//
//  ViewController.m
//  MLRecorder
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import "ViewController.h"
#import "MLAudioRecorder.h"
#import "CafRecordWriter.h"
#import "AmrRecordWriter.h"
#import "Mp3RecordWriter.h"
#import <AVFoundation/AVFoundation.h>
#import "MLAudioMeterObserver.h"

@interface ViewController ()

@property (nonatomic, strong) MLAudioRecorder *recorder;
@property (nonatomic, strong) CafRecordWriter *cafWriter;
@property (nonatomic, strong) AmrRecordWriter *amrWriter;
@property (nonatomic, strong) Mp3RecordWriter *mp3Writer;

@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, copy) NSString *filePath;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) MLAudioMeterObserver *meterObserver;
@end

@implementation ViewController

- (void)dealloc
{
    //音谱检测关联着录音类，录音类要停止了。所以要设置其audioQueue为nil
    self.meterObserver.audioQueue = nil;
	[self.recorder stopRecording];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    CafRecordWriter *writer = [[CafRecordWriter alloc]init];
    writer.filePath = [path stringByAppendingPathComponent:@"record.caf"];
    self.cafWriter = writer;
    
    AmrRecordWriter *amrWriter = [[AmrRecordWriter alloc]init];
    amrWriter.filePath = [path stringByAppendingPathComponent:@"record.amr"];
    amrWriter.maxSecondCount = 60;
    amrWriter.maxFileSize = 1024*256;
    amrWriter.cafFilePath = [path stringByAppendingPathComponent:@"recordAmr.caf"];
    self.amrWriter = amrWriter;
    
    Mp3RecordWriter *mp3Writer = [[Mp3RecordWriter alloc]init];
    mp3Writer.filePath = [path stringByAppendingPathComponent:@"record.mp3"];
    mp3Writer.maxSecondCount = 60;
    mp3Writer.maxFileSize = 1024*256;
    self.mp3Writer = mp3Writer;
    
    MLAudioMeterObserver *meterObserver = [[MLAudioMeterObserver alloc]init];
    meterObserver.actionBlock = ^(NSArray *levelMeterStates,MLAudioMeterObserver *meterObserver){
        NSLog(@"volume:%f",[MLAudioMeterObserver volumeForLevelMeterStates:levelMeterStates]);
    };
    meterObserver.errorBlock = ^(NSError *error,MLAudioMeterObserver *meterObserver){
        [[[UIAlertView alloc]initWithTitle:@"错误" message:error.userInfo[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil]show];
    };
    self.meterObserver = meterObserver;
    
    MLAudioRecorder *recorder = [[MLAudioRecorder alloc]init];
    __weak __typeof(self)weakSelf = self;
    recorder.receiveStoppedBlock = ^{
        [weakSelf.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        weakSelf.meterObserver.audioQueue = nil;
    };
    recorder.receiveErrorBlock = ^(NSError *error){
        [weakSelf.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        weakSelf.meterObserver.audioQueue = nil;

        [[[UIAlertView alloc]initWithTitle:@"错误" message:error.userInfo[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil]show];
    };
    
    
    //caf
    //    recorder.fileWriterDelegate = writer;
    //    self.filePath = writer.filePath;
    
    //amr
    recorder.bufferDurationSeconds = 0.04;
    recorder.fileWriterDelegate = amrWriter;
    self.filePath  = amrWriter.cafFilePath; //因为能直接播放是的caf文件，所以给予caf文件地址
    
    //mp3
    //    recorder.fileWriterDelegate = mp3Writer;
    //    self.filePath = mp3Writer.filePath;
    
    self.recorder = recorder;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)record:(id)sender {
    UIButton *recordButton = (UIButton*)sender;
    
    if (self.recorder.isRecording) {
        //取消录音
        [self.recorder stopRecording];
    }else{
        [recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        //开始录音
        [self.recorder startRecording];
        self.meterObserver.audioQueue = self.recorder->_audioQueue;
    }
}

- (IBAction)play:(id)sender {
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:self.filePath] error:nil];
    [self.player play];
    
}

@end
