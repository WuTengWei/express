
#import "FYExpressHistoryController.h"
#import "FYExpressTracesController.h"
#import "FYDBTools.h"

@interface FYExpressHistoryController ()
<UITableViewDelegate,
UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic,strong) NSArray *expressHistory;

@end

@implementation FYExpressHistoryController

NSString* shipperCode2;//快递名称
NSString* logisticCode2;//快递单号
NSString* expressForUser2;//快递备注
NSArray* expressTraces2;//快递轨迹

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 获取搜索历史
    self.expressHistory = [FYDBTools statusesWithParams:@""];
    
    [_tableView reloadData];
}
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.expressHistory count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
  UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    NSDictionary *dict = self.expressHistory[indexPath.row];
    shipperCode2 = [dict objectForKey:@"ShipperCode"];
    logisticCode2 = [dict objectForKey:@"LogisticCode"];
    cell.textLabel.text = [NSString stringWithFormat:@"快递类型:%@    单号:%@",shipperCode2,logisticCode2];
    
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.textColor = [UIColor darkTextColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *dict = self.expressHistory[indexPath.row];
    
    NSMutableArray* expressTraces = [[NSMutableArray alloc]init];
    
    for (NSDictionary* traces in [dict objectForKey:@"Traces"]) {
        
        [expressTraces insertObject:traces atIndex:0];
    }
    
    NSString* shipperCode = [dict objectForKey:@"ShipperCode"];
    NSString* logisticCode = [dict objectForKey:@"LogisticCode"];
    
    ExpressInfo* express = [[ExpressInfo alloc]initWitfShipperCode:shipperCode
                                                   andlogisticCode:logisticCode
                                                  andexpressTraces:expressTraces];
    
    FYExpressTracesController* expressTracesVC = [[FYExpressTracesController alloc]init];
    expressTracesVC.express = express;
    expressTracesVC.isHistory = YES;
    [self.navigationController pushViewController:expressTracesVC animated:YES];
    
}

- (NSArray *)expressHistory {
    if (!_expressHistory) {
        _expressHistory = [NSArray array];
    }
    return _expressHistory;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
