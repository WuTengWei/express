
#import "FYHomePageController.h"
#import "AFNetworking.h"
#import "Base64Additions.h"
#import "MD5.h"
#import "ExpressInfo.h"
#import "FYExpressTracesController.h"
#import "FYScanQRCodeController.h"

#define eBusinessID @"1651956"
#define appKey @"514f18a8-3bd7-468c-a7ea-a4cb6248c1ca"
#define reqURL @"http://api.kdniao.com/Ebusiness/EbusinessOrderHandle.aspx"

@interface FYHomePageController ()<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *expressNum; //快递单号

@property (nonatomic,strong) NSDictionary *dict;

@end

@implementation FYHomePageController

NSDictionary* expressNameAndCode;
NSString* shipperCodeUser;

-(void)viewDidAppear:(BOOL)animated{
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(haddleQRCode:) name:@"do" object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - 输入单号查询快递详情

- (IBAction)expressSearch:(UIButton *)button {
    //1、根据单号查询快递公司
    //2、查询物流信息
    //3、处理物流信息

    // 查询快递公司编码
    __weak typeof(self) weakSelf = self;
    [self fetchShipperCodeWithLogisticCode:self.expressNum.text
                             successHandle:^(NSArray *shippers) {
                                 
                                 if (shippers.count >0) {
                                     
                                     NSDictionary *dict = [shippers firstObject];
                                     
                                     shipperCodeUser = [dict objectForKey:@"ShipperCode"];
                                     
                                 }
        
                                // 根据快递公司编码和快递单号查询快递详情
                                [weakSelf fechExpressInfoWithShipperCode:shipperCodeUser
                                                            LogisticCode:weakSelf.expressNum.text];
        
                             } errorHandle:^(NSError * error) {
                                 NSLog(@"%@",error);
                             }];
}

/**
 查询物流详情

 @param ShipperCode 快递公司编码
 @param LogisticCode 快递单号
 */
- (void)fechExpressInfoWithShipperCode:(NSString *)shipperCode
                          LogisticCode:(NSString *)logisticCode {

    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    
    NSString* requestData = [NSString stringWithFormat:@"{\"OrderCode\":\"\",\"ShipperCode\":\"%@\",\"LogisticCode\":\"%@\"}",
                             shipperCode,logisticCode];
    
    [params setObject:[requestData stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] forKey:@"RequestData"];
    
    // 签名规则 请求内容(未编码)+AppKey MD5 ，然后Base64编码，进行URL(utf-8)编码
    NSString* dataSignTmp = [[NSString alloc]initWithFormat:@"%@%@",requestData,appKey];
    
    NSString* dataSign = [[MD5 md5String:dataSignTmp] base64String];
    
    [params setObject:[dataSign stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] forKey:@"DataSign"];
    
    [params setObject:eBusinessID forKey:@"EBusinessID"];  //商户 ID
    
    [params setObject:@"1002" forKey:@"RequestType"];  //请求指令 1002 即时查询  2002 单号识别
    
    [params setObject:@"2" forKey:@"DataType"];  //请求返回数据类型 2 json
    
    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:reqURL parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                             options:0
                                                               error:nil];
        NSLog(@"请求成功：%@",json);
        
        // 快递轨迹
        NSMutableArray* expressTraces = [[NSMutableArray alloc]init];
        for (NSDictionary* traces in [json objectForKey:@"Traces"]) {
            [expressTraces insertObject:traces atIndex:0];
        }
        
        // 快递公司编码
        NSString* shipperCode = [json objectForKey:@"ShipperCode"];
        // 快递单号
        NSString* logisticCode = [json objectForKey:@"LogisticCode"];
        
        ExpressInfo* express = [[ExpressInfo alloc]initWitfShipperCode:shipperCode
                                                       andlogisticCode:logisticCode
                                                      andexpressTraces:expressTraces];
        // 跳转快递轨迹详情
        FYExpressTracesController* expressTracesVC = [[FYExpressTracesController alloc]init];
        expressTracesVC.express = express;
        expressTracesVC.expressdict = json;
        self.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:expressTracesVC animated:YES];
        self.hidesBottomBarWhenPushed = NO;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败：%@",error.description);
    }];
}

/**
 自动识别快递公司编码 (单号识别)
 
 @param LogisticCode 快递单号
 @param successHandle 成功回调公司编码信息
 @param errorHandle 错误回调 773043492361968
 */
- (void)fetchShipperCodeWithLogisticCode:(NSString *)logisticCode
                                 successHandle:(void(^)(NSArray * shippers))successHandle
                                   errorHandle:(void(^)(NSError * error))errorHandle {
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    NSString* requestData = [NSString stringWithFormat:@"{\"LogisticCode\":\"%@\"}",
                             logisticCode];
    
    [params setObject:[requestData stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] forKey:@"RequestData"];
    
    //签名规则 请求内容(未编码)+AppKey MD5 ，然后Base64编码，进行URL(utf-8)编码
    
    NSString* dataSignTmp = [[NSString alloc]initWithFormat:@"%@%@",requestData,appKey];
    
    NSString* dataSign = [[MD5 md5String:dataSignTmp] base64String];
    
    [params setObject:[dataSign stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] forKey:@"DataSign"];
    
    [params setObject:eBusinessID forKey:@"EBusinessID"];  //商户 ID
    
    [params setObject:@"2002" forKey:@"RequestType"];  //请求指令 1002 即时查询  2002 单号识别
    
    [params setObject:@"2" forKey:@"DataType"];  //请求返回数据类型 2 json
    
    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:reqURL parameters:params
         progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                             options:0
                                                               error:nil];
        NSLog(@" ==== 查询快递公司编码成功===== %@",json);
        successHandle([json objectForKey:@"Shippers"]);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        errorHandle(error);
        NSLog(@" ===== 查询快递公司编码失败==== %@",error.description);
    }];
}

#pragma mark - 二维码扫描查询

-(void)haddleQRCode:(NSNotification*)sender{
    
    // 扫描结果
    NSDictionary* dc = sender.userInfo;
    
    if (self.dict == dc) return;
    
    self.dict = dc;
    
    NSLog(@"sender:%@",[dc objectForKey:@"userInfo"]);
    
    self.expressNum.text = [dc objectForKey:@"userInfo"];
    
    // 查询
    [self expressSearch:nil];
}

#pragma mark 关闭键盘
-(void) hiddenKeyboard{
    [self.expressNum resignFirstResponder];
}

- (NSDictionary *)dict {
    if (!_dict) {
        _dict = [NSDictionary dictionary];
    }
    return _dict;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

@end
