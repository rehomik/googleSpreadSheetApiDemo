//
//  ViewController.m
//  docstest
//
//  Created by Kim Jae Beom on 12. 10. 14..
//  Copyright (c) 2012년 doouky. All rights reserved.
//

#import "ViewController.h"

// 인증 관련
#import "GTMOAuth2ViewControllerTouch.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // docs 읽어오는 코드.
    //
    // Google Spread sheet 서비스를 생성한다.
    service_ = [[GDataServiceGoogleSpreadsheet alloc] init];
    
    [service_ setShouldCacheResponseData:YES];
    [service_ setServiceShouldFollowNextLinks:YES];
    
    // 계정하고 비번 입력.
    [service_ setUserCredentialsWithUsername: @"구글계정"
                                    password: @"비번"];
    
    // spread sheet URL 생성.
    NSURL* feed_url =
    [NSURL URLWithString: kGDataGoogleSpreadsheetsPrivateFullFeed];
    
    // 서비스를 요청함.
    [service_ fetchFeedWithURL: feed_url
                      delegate: self
             didFinishSelector: @selector(feedTicket:finishedWithFeed:error:)];
}

// 서비스 요청 응답 콜백
- (void)feedTicket: (GDataServiceTicket *)ticket
  finishedWithFeed: (GDataFeedSpreadsheet *)feed
             error: (NSError *)error
{
    // spread sheet를 모두 얻어온다.
    // Google Docs 웹사이트에서 전체 문서함 순서와 동일하다.
    NSArray* feed_array = [feed entries];
    
    if (0 == [feed_array count])
    {
        NSLog(@"spread sheet error");
        
        return;
    }
    
    // spread sheet를 선택.
    for (int index = 0; index < [feed_array count]; ++index)
    {
        GDataEntrySpreadsheet* entry_sheet =
        [feed_array objectAtIndex: index];
        
        // api test라는 제목을 가진 문서를 검색한다.
        if ([[entry_sheet.title stringValue] isEqualToString: @"api test"])
        {
            // 해당 spread sheet의 work sheet를 요청한다.
            [service_ fetchFeedWithURL: [entry_sheet worksheetsFeedURL]
                              delegate: self
                     didFinishSelector: @selector(worksheetsTicket:finishedWithFeed:error:)];
            
            return;
        }
    }
}

// work sheet 응답 콜백
- (void)worksheetsTicket:(GDataServiceTicket *)ticket
        finishedWithFeed:(GDataFeedWorksheet *)feed
                   error:(NSError *)error
{
    NSArray* feed_array = [feed entries];
    
    if (0 == [feed_array count])
    {
        NSLog(@"work sheet error");
        
        return;
    }
    
    GDataEntryWorksheet* entry_work_sheet = [feed_array objectAtIndex: 0];
    
    GDataQuerySpreadsheet* query_sheet =
    [[GDataQuerySpreadsheet alloc] initWithFeedURL:
     [[entry_work_sheet cellsLink] URL]];
    
    [service_ fetchFeedWithQuery: query_sheet
               completionHandler: ^(GDataServiceTicket* ticket, GDataFeedBase* feed, NSError* error)
     {
         GDataFeedSpreadsheetCell* feed_cell = (GDataFeedSpreadsheetCell*)feed;
         
         // index는 가로로 증가한다. a1=0, a2=1 이런식.
         GDataEntrySpreadsheetCell* cell = [feed_cell.entries objectAtIndex: 0];
         
         // A1에 해당하는 곳에 뭐라도 하나 적혀있어야 cell이 리턴된다.
         if ([cell.title.stringValue isEqualToString: @"A1"])
         {
             GDataSpreadsheetCell* cell_data = [cell cell];
             
             [cell_data setInputString: @"THIS IS TSET!"];
             
             [service_ fetchEntryByUpdatingEntry: cell
                                     forEntryURL: [[cell editLink] URL]
                               completionHandler: ^(GDataServiceTicket* ticket,
                                                    GDataEntryBase* entry,
                                                    NSError* error)
              {
                  NSLog(@"%@", entry);
              }];
         }
     }];
    
//    // work sheet 내부의 값들을 list 형태로 요청하기 위한 url을 얻어온다.
//    // list 형태는 최종적으로 값을 읽었을 때 한행의 모든 값을 한번에 읽어온다.
//    NSURL* feed_url = [entry_work_sheet listFeedURL];
//    
//    [service_ fetchFeedWithURL: feed_url
//                      delegate: self
//             didFinishSelector: @selector(entriesTicket:finishedWithFeed:error:)];
}

//- (void)entriesTicket:(GDataServiceTicket *)ticket
//     finishedWithFeed:(GDataFeedBase *)feed
//                error:(NSError *)error
//{
//    NSArray* feed_array = [feed entries];
//    
//    if (0 == [feed_array count])
//    {
//        NSLog(@"feed base error");
//        
//        return;
//    }
//    
//    // 최종적으로 어어온 work sheet 안의 값.
//    GDataEntryBase* base = [feed_array objectAtIndex: 1];
//    
//    NSLog(@"%@", base);
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
