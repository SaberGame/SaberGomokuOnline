//
//  PickerViewController.m
//  ChessGame
//
//  Created by songlong on 16/9/14.
//  Copyright © 2016年 Saber. All rights reserved.
//

#import "PickerViewController.h"

@interface PickerViewController ()<UITableViewDelegate, UITableViewDataSource,NSNetServiceBrowserDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *servicesArray;
@property (nonatomic, strong) UILabel *localServiceNameLabel;
@property (nonatomic, strong) NSNetServiceBrowser *browser;

@property (nonatomic, strong) UIView *connectView;

@end

@implementation PickerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _localServiceNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 20)];
        self.servicesArray = [NSMutableArray array];
        [self addObserver:self forKeyPath:@"localService" options:0 context:&self->_localService];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"localService" context:&self->_localService];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self setupLocalServiceNameLabel];
    
}

- (void)setupUI {
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == &self->_localService) {
        assert([keyPath isEqual:@"localService"]);
        assert(object == self);
        
        if (self.localServiceNameLabel != nil) {
            [self setupLocalServiceNameLabel];
        }
        
        
        if (self.browser != nil) {
            [self stop];
            [self start];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)start {
    assert([self.servicesArray count] == 0);
    assert(self.browser == nil);
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.includesPeerToPeer = YES;
    self.browser.delegate = self;
    [self.browser searchForServicesOfType:self.type inDomain:@"local"];
}

- (void)stop {
    [self.browser stop];
    self.browser = nil;
    [self.servicesArray removeAllObjects];
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)cancelConnect {
    [self hideConnectViewAndNotify:NO];
}

- (void)setupLocalServiceNameLabel {
    assert(self.localServiceNameLabel != nil);
    if (self.localService == nil) {
        self.localServiceNameLabel.text = @"registering...";
    } else {
        self.localServiceNameLabel.text = self.localService.name;
    }
}

#pragma UITableView Delegate / DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.servicesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *resuseID = @"picker_cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: resuseID];
    }
    
    NSNetService *service = self.servicesArray[indexPath.row];
    
    cell.textLabel.text = service.name;
    cell.textLabel.textColor = [UIColor blueColor];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100)];
    
    UILabel *nameInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    nameInfoLabel.text = @"本机名字：";
    nameInfoLabel.textAlignment = NSTextAlignmentCenter;
    nameInfoLabel.textColor = [UIColor blackColor];
    [headerView addSubview:nameInfoLabel];
    
    
    _localServiceNameLabel.textAlignment = NSTextAlignmentCenter;
    _localServiceNameLabel.textColor = [UIColor redColor];
    [headerView addSubview:_localServiceNameLabel];
    
    UILabel *waitingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width, 20)];
    waitingLabel.text = @"其它玩家列表：";
    waitingLabel.textAlignment = NSTextAlignmentCenter;
    waitingLabel.textColor = [UIColor blackColor];
    [headerView addSubview:waitingLabel];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNetService *service = self.servicesArray[indexPath.row];
    [self showConnectViewForService:service];
}

- (void)showConnectViewForService:(NSNetService *)service {
    _connectView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 4, [UIScreen mainScreen].bounds.size.height / 4, [UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2)];
    _connectView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_connectView];
    
    UILabel *connectLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width / 2, 20)];
    connectLabel.textColor = [UIColor blackColor];
    connectLabel.textAlignment = NSTextAlignmentCenter;
    connectLabel.text = [NSString stringWithFormat:@"Connecting To %@", service.name];
    [_connectView addSubview:connectLabel];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 30, [UIScreen mainScreen].bounds.size.width / 2, 30)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(clickCancel) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_connectView addSubview:cancelButton];
    
    self.tableView.scrollEnabled = NO;
    self.tableView.allowsSelection = NO;
    
    [self.delegate pickerViewController:self connectToService:service];
}

- (void)clickCancel {
    [self hideConnectViewAndNotify:YES];
}
- (void)hideConnectViewAndNotify:(BOOL)notify {
    
    if (self.connectView.superview != nil) {
        
        [self.connectView removeFromSuperview];
        self.tableView.scrollEnabled = YES;
        self.tableView.allowsSelection = YES;
    }
    
    if (notify) {
        [self.delegate pickerViewControllerDidCancelConnect:self];
    }
}

#pragma mark * Browser view callbacks

- (void)sortAndReloadTable
{
    // Sort the services by name.
    
    [self.servicesArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name] localizedCaseInsensitiveCompare:[obj2 name]];
    }];
    
    // Reload if the view is loaded.
    
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
#pragma unused(browser)
    assert(service != nil);
    
    // Remove the service from our array (assume it's there, of course).
    
    if ( (self.localService == nil) || ! [self.localService isEqual:service] ) {
        [self.servicesArray removeObject:service];
    }
    
    // Only update the UI once we get the no-more-coming indication.
    
    if ( ! moreComing ) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
#pragma unused(browser)
    assert(service != nil);
    
    // Add the service to our array (unless its our own service).
    
    if ( (self.localService == nil) || ! [self.localService isEqual:service] ) {
        [self.servicesArray addObject:service];
    }
    
    // Only update the UI once we get the no-more-coming indication.
    
    if ( ! moreComing ) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict
{
    assert(browser == self.browser);
#pragma unused(browser)
    assert(errorDict != nil);
#pragma unused(errorDict)
    assert(NO);         // The usual reason for us not searching is a programming error.
}


@end
