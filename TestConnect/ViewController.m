//
//  ViewController.m
//  TestConnect
//
//  Created by annidy on 2022/2/14.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionTaskDelegate>
@property IBOutlet UILabel *urlLabel;
@property IBOutlet UITextView *contentView;
@property NSURLSession *session;
@property NSURLSessionTaskMetrics *metric;
@property NSDate *startDate;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.session = session;
}

- (IBAction)request:(id)sender
{
    NSURL *URL = [NSURL URLWithString:self.urlLabel.text];
    NSMutableURLRequest *r = [[NSMutableURLRequest alloc] initWithURL:URL];
    [r addValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [r setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    
    NSURLSessionTask *task = [self.session dataTaskWithRequest:r];
    if (@available(iOS 15.0, *)) {
        task.delegate = self;
    } else {
        // Fallback on earlier versions
    }
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    self.metric = metrics;
    for (NSURLSessionTaskTransactionMetrics *trans in metrics.transactionMetrics) {
        NSMutableString *text = [NSMutableString new];
        [text appendFormat:@"fstart %@;", [self formatDate:trans.fetchStartDate]];
        NSInteger dns = MAX(([trans.domainLookupEndDate timeIntervalSince1970] - [trans.domainLookupStartDate timeIntervalSince1970]) * 1000, 0);
        [text appendFormat:@"dns %ld;", dns];
        NSInteger tcp = MAX(([trans.secureConnectionStartDate timeIntervalSince1970] - [trans.connectStartDate timeIntervalSince1970]) * 1000, 0);
        [text appendFormat:@"tcp %ld;", tcp];
        NSInteger ssl = MAX(([trans.secureConnectionEndDate timeIntervalSince1970] - [trans.secureConnectionStartDate timeIntervalSince1970]) * 1000, 0);
        [text appendFormat:@"ssl %ld;", ssl];
        NSInteger send = MAX(([trans.requestEndDate timeIntervalSince1970] - [trans.requestStartDate timeIntervalSince1970]) * 1000, 0);
        NSInteger wait = MAX(([trans.responseStartDate timeIntervalSince1970] - [trans.requestEndDate timeIntervalSince1970]) * 1000, 0);
        NSInteger reuseConnect = trans.isReusedConnection;
        [text appendFormat:@"reuse %ld;", reuseConnect];
        NSInteger receive = MAX(([trans.responseEndDate timeIntervalSince1970] - [trans.responseStartDate timeIntervalSince1970]) * 1000, 0);
        
        [self recode:text];
    }
//    [self recode:[metrics debugDescription]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(nullable NSError *)error
{
    if (error) {
        [self recode:[error debugDescription]];
    }
}

- (void)recode:(NSString *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.contentView.text = [NSString stringWithFormat:@"%@\n%@", self.contentView.text, data];
        CGPoint bottomOffset = CGPointMake(0, self.contentView.contentSize.height - self.contentView.bounds.size.height + self.contentView.contentInset.bottom);
        [self.contentView setContentOffset:bottomOffset animated:YES];
    });
}

- (NSString *)nowString {
    NSDate* now = [NSDate date];
    return [self formatDate:now];
}

- (NSString *)formatDate:(NSDate *)now {
    static NSDateFormatter* fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        fmt.dateFormat = @"HH:mm:ss:SSS";
    });
    
    NSString* dateString = [fmt stringFromDate:now];
    return dateString;
}


@end
