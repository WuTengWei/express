

#import "FYScanQRCodeController.h"
#import <AVFoundation/AVFoundation.h>
#import "FYHomePageController.h"

@interface FYScanQRCodeController ()

<UITabBarDelegate,
AVCaptureMetadataOutputObjectsDelegate,  // 扫描获取到数据后的回调
AVCaptureVideoDataOutputSampleBufferDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    NSTimer *timer;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@property (strong, nonatomic) AVCaptureSession* session;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer* previewLayer;

@property (strong, nonatomic) AVCaptureMetadataOutput* output;

@property (strong, nonatomic) AVCaptureDeviceInput* input;

@property (strong, nonatomic) AVCaptureDevice* device;

//边框
@property (strong, nonatomic) IBOutlet UIView *customContainerView;
// 冲击波view
@property (strong, nonatomic) IBOutlet UIImageView *scanLineImageView;
// 底部提示
@property (strong, nonatomic) IBOutlet UILabel *customLabel;
// 底部切换 bar
@property (strong, nonatomic) IBOutlet UITabBar *customBar;

// 用于保存描边的图层
@property (strong, nonatomic) CALayer* containerLayer;

@end

@implementation FYScanQRCodeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.customBar.hidden = NO;
    
    self.customBar.selectedItem = self.customBar.items.firstObject;
    
    self.customBar.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self initTimer];
    [self scanSetup];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.session stopRunning];
    [timer invalidate];
    timer = nil;
    [NSUserDefaults resetStandardUserDefaults];
}

#pragma mark - 关闭和打开相册

// 关闭
- (IBAction)closeButtonClick:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 打开相册
- (IBAction)openCameraClick:(id)sender {
    
    // 1.判断相册是否可以打开
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        
        return;
    }
    
    // 2. 创建图片选择控制器
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // 3.设置代理
    picker.delegate = self;
    
    // 4.modal出这个控制器
    [self presentViewController:picker animated:YES completion:nil];
    
}

#pragma mark - UIImagePickerControllerDelegate

/// 相册选取图片扫描
/// @param picker
/// @param info
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 1.取出选中的图片
    UIImage *pickImage = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(pickImage);
    CIImage *ciImage = [CIImage imageWithData:imageData];
    
    // 2.从选中的图片中读取二维码数据
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    
    // 探测数据
    NSArray *feature = [detector featuresInImage:ciImage];
    
    // 取出数据
    for (CIQRCodeFeature *result in feature) {
        
        NSLog(@"%@",result.messageString);
                
         // 发送通知查询快递信息
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:result.messageString forKey:@"userInfo"];
                
        [[NSNotificationCenter defaultCenter] postNotificationName:@"do" object:self userInfo:userInfo];
        
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}


#pragma mark - 懒加载

- (AVCaptureDevice *)device
{
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

- (AVCaptureDeviceInput *)input
{
    if (!_input) {
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _input;
}

- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        
        if ([_session canAddInput:self.input]){
            [_session addInput:self.input];
        }
        
        if ([_session canAddOutput:self.output]){
            [_session addOutput:self.output];
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResize;
    }
    return _previewLayer;
}

- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc] init];
        
        // 1.获取屏幕的frame
        CGRect viewRect = self.view.frame;
        
        // 2.获取扫描容器的frame
        CGRect containerRect = self.customContainerView.frame;
        
        CGFloat x = containerRect.origin.y / viewRect.size.height;
        CGFloat y = containerRect.origin.x / viewRect.size.width;
        CGFloat width = containerRect.size.height / viewRect.size.height;
        CGFloat height = containerRect.size.width / viewRect.size.width;
        
        // 设置扫描区域
        _output.rectOfInterest = CGRectMake(x, y, width, height);
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }
    return _output;
}

- (CALayer *)containerLayer
{
    if (_containerLayer == nil) {
        _containerLayer = [[CALayer alloc] init];
    }
    return _containerLayer;
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    
    if ([metadataObjects count] > 0){
        
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        
        if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            
            NSString *stringValue = [metadataObject stringValue];
            
            self.customLabel.text = stringValue;
            
            if (stringValue != nil) {
                
                 [self.session stopRunning];
            }
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:stringValue forKey:@"userInfo"];
            
            [self clearLayers];
            
            [self dismissViewControllerAnimated:YES completion:^{
                               
                [[NSNotificationCenter defaultCenter] postNotificationName:@"do" object:self userInfo:userInfo];
                
            }];
            
        }
    }
}

- (void)clearLayers
{
    if (self.containerLayer.sublayers)
    {
        for (CALayer *subLayer in self.containerLayer.sublayers)
        {
            [subLayer removeFromSuperlayer];
        }
    }
}

- (void) initTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:0.004 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self.topConstraint.constant +=1;
        if (self.topConstraint.constant == 250) {
            self.topConstraint.constant = 0;
        }
    }];
}

- (void)scanSetup {
    
    [self.view.layer addSublayer:self.containerLayer];
      
    self.containerLayer.frame = self.view.bounds;
    
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
        
    // AVMetadataObjectTypeQRCode 二维码
    // 其他为条形码
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,
                                          AVMetadataObjectTypeEAN13Code,
                                          AVMetadataObjectTypeEAN8Code,
                                          AVMetadataObjectTypeUPCECode,
                                          AVMetadataObjectTypeCode39Code,
                                          AVMetadataObjectTypeCode39Mod43Code,
                                          AVMetadataObjectTypeCode93Code,
                                          AVMetadataObjectTypeCode128Code,
                                          AVMetadataObjectTypePDF417Code]];
    [self.session startRunning];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    // 刷新UI
    [self.view layoutIfNeeded];
    
    // 移除动画
    [self.scanLineImageView.layer removeAllAnimations];
}

@end
