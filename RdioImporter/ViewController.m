//
//  ViewController.m
//  RdioImporter
//
//  Created by James Hall on 3/18/16.
//  Copyright © 2016 Hall & Co. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
//#import "TBXML.h"
#import "XMLReader.h"
#import <Spotify/Spotify.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *switchFollow;
@property (weak, nonatomic) IBOutlet UILabel *lblSpotifyAlbumInfo;
@property (weak, nonatomic) IBOutlet UILabel *lblRdioInfo;
@property (weak, nonatomic) IBOutlet UIScrollView *svItems;
@property (weak, nonatomic) IBOutlet UILabel *lblAlbumCount;

@property (nonatomic, strong) SPTListPage *currentPage;
@property (nonatomic,strong)SPTPartialAlbum *selectedAlbum;
@property (nonatomic,strong) NSMutableArray *albums;
@property (nonatomic, assign) NSUInteger count;
@property (weak, nonatomic) IBOutlet UILabel *lblloadingLine1;
@property (weak, nonatomic) IBOutlet UILabel *lblLoadingLine2;
@property (weak, nonatomic) IBOutlet UILabel *lblLoadingLine3;
@property (weak, nonatomic) IBOutlet UIView *vwLoadingView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.albums = [[NSMutableArray alloc]init];
    self.count = 0;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)hideLoadingView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lblloadingLine1 setText:@""];
        [self.lblLoadingLine2 setText:@""];

            [self.lblLoadingLine3 setText:@""];
        
        [self.vwLoadingView setAlpha:0.0f];
        
        [self.vwLoadingView setHidden:NO];
    });
}
- (IBAction)btnSavePress:(id)sender {
    

    NSArray * array = [[SPTAuth defaultInstance] requestedScopes];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lblloadingLine1 setText:@"Saving Information"];
        [self.lblLoadingLine2 setText:@"..."];
        if(self.switchFollow.on){
            [self.lblLoadingLine3 setText:@"..."];
        }else{
            [self.lblLoadingLine3 setText:@""];
        }
        
        [self.vwLoadingView setAlpha:0.95];
        
        [self.vwLoadingView setHidden:NO];
    });
    
    [SPTAlbum albumWithURI:self.selectedAlbum.uri accessToken:nil market:@"US" callback:^(NSError *error, id object){
        SPTAlbum *album = object;

        int i = 0;
        i++;
        NSError *error2;
        
        //new scope
        {
            NSMutableArray *artists = [[NSMutableArray alloc]init];
            for (SPTPartialArtist *artist in album.artists) {
                [artists addObject:artist.identifier];
            }
            
            
            NSMutableURLRequest *rere = [[SPTFollow createRequestForFollowingUsers:artists
                                                                   withAccessToken:[[[SPTAuth defaultInstance] session] accessToken]
                                                                             error:&error2]  mutableCopy];
            
            
            NSURL * url = rere.URL;
            NSString * urlString = url.absoluteString;
            NSURL * newURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/me/albums?ids=%@",album.identifier]];
            [rere setURL: newURL];
            
            [[SPTRequest sharedHandler] performRequest:rere callback:^(NSError *error, NSURLResponse *response, NSData *data) {
                long statusCode = ((NSHTTPURLResponse*)response).statusCode;
                NSString *retString = @"";
                switch (statusCode) {
                    case 204:
                        retString = @"Successfully followed artist.";
                        break;
                    case 401:
                    case 403:
                        retString = @"Failed to follow user, are you sure your token is valid and have the correct scopes?";
                        break;
                        
                    case 200:
                        retString = @"Album Saved.";
                        break;
                    default:
                        retString = @"Unknown error";
                        break;
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    [self.lblLoadingLine2 setText:retString];
                });
                if(!self.switchFollow.on){
                    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(hideLoadingView) userInfo:nil repeats:NO];
                }
            }];
        }
        
        if(self.switchFollow.on) // Follow the Artist
        {

            NSMutableArray *artists = [[NSMutableArray alloc]init];
            for (SPTPartialArtist *artist in album.artists) {
                [artists addObject:artist.identifier];
            }

            
            NSMutableURLRequest *rere = [[SPTFollow createRequestForFollowingUsers:artists
                                                           withAccessToken:[[[SPTAuth defaultInstance] session] accessToken]
                                                                     error:&error2]  mutableCopy];
            
            
            NSURL * url = rere.URL;
            NSString * urlString = url.absoluteString;
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"user" withString:@"artist"];
            NSURL * newURL = [NSURL URLWithString:newUrlString];
            [rere setURL: newURL];

            [[SPTRequest sharedHandler] performRequest:rere callback:^(NSError *error, NSURLResponse *response, NSData *data) {
                long statusCode = ((NSHTTPURLResponse*)response).statusCode;
                                NSString *retString = @"";
                switch (statusCode) {
                    case 204:
                        retString = @"Successfully followed artist.";
                        break;
                    case 401:
                    case 403:
                        retString = @"Failed to follow user, are you sure your token is valid and have the correct scopes?";
                        break;
                    default:
                        retString = @"Unknown error";
                        break;
                        
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    [self.lblLoadingLine3 setText:retString];
                    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(hideLoadingView) userInfo:nil repeats:NO];
                });
            }];
        }
        
    }];
    
    
}
- (IBAction)btnSkipPress:(id)sender {
    self.count ++;
    
    
    [self.lblAlbumCount setText:[NSString stringWithFormat:@"%lu of %lu albums",self.count,self.albums.count]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithLong:self.count] forKey:@"currentCount"];
    
    [defaults synchronize];
    
    [self loadInformation];
}
- (IBAction)btnLoadAlbums:(id)sender {
    

    
    NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"favorites_albumsandsongs" withExtension:@"xspf"];
    NSString*stringPath = [imgPath absoluteString]; //this is correct
    
    //you can again use it in NSURL eg if you have async loading images and your mechanism
    //uses only url like mine (but sometimes i need local files to load)
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
    
    NSError *error = nil;
    NSDictionary *dict = [XMLReader dictionaryForXMLData:data error:&error];
    
    NSDictionary *list = [dict objectForKey:@"playlist"];
    NSDictionary *playlist = [list objectForKey:@"trackList"];
    NSArray *alltracks = [playlist objectForKey:@"track"];
    
    NSMutableDictionary * album;
    album = [[NSMutableDictionary alloc]init];
    for (NSDictionary *trackInfo in alltracks) {
//        NSLog(@"%@ - %@", [[trackInfo objectForKey:@"creator"] objectForKey:@"text"],
//              [[trackInfo objectForKey:@"album"] objectForKey:@"text"]);
        
        
        if(![[[trackInfo objectForKey:@"album"] objectForKey:@"text"] isEqualToString:[album valueForKey:@"album"]] && [album allKeys].count > 0){
            [self.albums addObject:album];
//            NSLog(@"Adding: %@ - %@", [album valueForKey:@"artist"], [album valueForKey:@"album"]);
            album = [[NSMutableDictionary alloc]init];
        }
        [album setValue:[[trackInfo objectForKey:@"creator"] objectForKey:@"text"] forKey:@"artist"];
        [album setValue:[[trackInfo objectForKey:@"album"] objectForKey:@"text"] forKey:@"album"];
    }
    [self.albums addObject:album];
//    NSLog(@"Adding: %@ - %@", [album valueForKey:@"artist"], [album valueForKey:@"album"]);
    NSLog(@"Total Albums - %lu",self.albums.count);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *currentCount = [defaults objectForKey:@"currentCount"];
    if(currentCount != nil){
        self.count = [currentCount doubleValue];
    }
    [self loadInformation];
    
    
}

-(void)loadInformation{
    for (UIView *vw in self.svItems.subviews) {
        [vw removeFromSuperview];
    }
    [self.svItems setContentOffset:CGPointMake(0, 0)];
    [self.svItems setContentSize:CGSizeMake(300, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lblloadingLine1 setText:@""];
        [self.lblLoadingLine2 setText:[NSString stringWithFormat:@"Loading Albums for %@",[self.albums[self.count] objectForKey:@"album"]]];
        [self.lblLoadingLine3 setText:@""];
        
        [self.vwLoadingView setAlpha:0.95];

        [self.vwLoadingView setHidden:NO];
    });
    
    [SPTSearch performSearchWithQuery:[self.albums[self.count] objectForKey:@"album"] queryType:SPTQueryTypeAlbum accessToken:nil callback:^(NSError *error,id obj){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.vwLoadingView setAlpha:0.0f];
        });
        self.currentPage = obj;
        int i = 0;
        for (SPTPartialAlbum *album in self.currentPage.items) {
            
            NSData * imageData = [NSData dataWithContentsOfURL:album.largestCover.imageURL];
            UIImage * image = [UIImage imageWithData:imageData];
            UIImageView *albumImage =[[UIImageView alloc]initWithFrame:CGRectMake((i * 160)+12, 0, 150, 150)];
            albumImage.image = image;
            [self.svItems addSubview:albumImage];
            
            UIButton *btnViewImage = [[UIButton alloc]initWithFrame:CGRectMake((i * 160)+12, 0, 150, 150)];
            [btnViewImage setBackgroundColor:[UIColor clearColor]];
            [btnViewImage setTag:i];
            [btnViewImage addTarget:self action:@selector(chosenItem:) forControlEvents:UIControlEventTouchUpInside];
            [self.svItems addSubview:btnViewImage];
            if(i == 0)
            {
                self.lblRdioInfo.text = [NSString stringWithFormat:@"%@ - %@",[self.albums[self.count] objectForKey:@"artist"],[self.albums[self.count] objectForKey:@"album"]];
                self.lblSpotifyAlbumInfo.text = [NSString stringWithFormat:@"%@",album.name];
            }
            
            i++;
        }
        [self.svItems setContentSize:CGSizeMake(i * 160, 150)];
        
        
    }];
    
}

-(void)chosenItem:(UIButton *) sender{
    
    [sender.layer setBorderWidth:4.0f];
    [sender.layer setBorderColor:[UIColor orangeColor].CGColor];
    
    SPTPartialAlbum *album = self.currentPage.items[sender.tag];
    self.selectedAlbum = album;
    self.lblSpotifyAlbumInfo.text = [NSString stringWithFormat:@"%@",album.name];
    for (id vw in self.svItems.subviews) {
        if([vw class] == [UIButton class]){
            UIButton *btn = vw;
            if (btn.tag != sender.tag) {
                [btn.layer setBorderWidth:0.0];
            }
        }
    }
    
}

@end
