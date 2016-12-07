//
//  MainVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "MainVC.h"

//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND

//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS

#import "Masonry.h"

#import "AudioRecordVC.h"

#import "VideoRecordVC.h"

#import "LiveVC.h"

#import "IJKPlayerVC.h"

#import "VideoEncodeVC.h"

#import "GPUImageVC.h"

#import "FFmpegAACEncodeVC.h"


@interface MainVC ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    [self createUpUI];
    
}

-(void)createUpUI{
    
    UITableView * tableView = [[UITableView alloc]init];
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:tableView];
    
    [tableView makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(0);
    }];
    
    tableView.dataSource = self;
    
    tableView.delegate = self;
    
}

#pragma mark -  dataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"音频录制";
            break;
        case 1:
            cell.textLabel.text = @"视频录制";
            break;
            
        case 2:
            cell.textLabel.text = @"直播采集";
            break;
            
        case 3:
            cell.textLabel.text = @"播放器搭建";
            break;
        case 4:
            cell.textLabel.text = @"视频流编码";
            break;
        case 5:
            cell.textLabel.text = @"GPUImage滤镜美颜";
            break;
        case 6:
            cell.textLabel.text = @"FFmpeg PCM->AAC";
            break;
        default:
            break;
    }
    
    return cell;
    
}

#pragma mark -  delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
        case 0:
        {
            AudioRecordVC * vc = [[AudioRecordVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 1:
        {
            VideoRecordVC * vc = [[VideoRecordVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 2:
        {
            LiveVC * vc = [[LiveVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 3:
        {
            IJKPlayerVC * vc = [[IJKPlayerVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 4:
        {
            VideoEncodeVC * vc = [[VideoEncodeVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 5:
        {
            GPUImageVC * vc = [[GPUImageVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 6:
        {
            FFmpegAACEncodeVC * vc = [[FFmpegAACEncodeVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
    
}
@end
