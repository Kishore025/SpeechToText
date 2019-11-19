//
//  ViewController.m
//  SpeechToText
//
//  Created by simpro on 17/09/19.
//  Copyright © 2019 Kishore. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextView *commandText;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
    // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSLog(@"Speech recognizer %@::::",speechRecognizer);
    
    // Set speech recognizer delegate
    speechRecognizer.delegate = self;
    
    // Request the authorization to make sure the user is asked for permission so you can
    // get an authorized response, also remember to change the .plist file, check the repo's
    // readme file or this projects info.plist
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"Not Determined");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            default:
                break;
        }
    }];
    
}

/*!
 * @brief Starts listening and recognizing user input through the phone's microphone
 */

- (void)startListening {
    
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Make sure there's not a recognition task already running
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result !=nil) {
            // Whatever you say in the mic after pressing the button should be being logged
            // in the console.
            NSString *resultString = result.bestTranscription.formattedString;
            NSLog(@"RESULT:%@",resultString);
            
            //            [self updateText:resultString];
            [self onlyGetLastWord:resultString];

            isFinal = !result.isFinal;
            NSLog(@"is final %d",isFinal);
        }

    }];
    
    
    // Sets the recording format
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    NSLog(@"Recording Format ::::%@",recordingFormat);
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self->recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say Something, I'm listening");
    [self updateText:@"Say Something, I'm listening"];

}

- (IBAction)GoButton:(id)sender {
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
        NSLog(@"audio engine stopped");
        [self updateText:@"audio engine stopped"];
    } else {
        [self startListening];
        NSLog(@"audio engine started");
        [self updateText:@"audio engine started"];
    }
    
}
- (IBAction)StopButton:(id)sender {
//    [audioEngine stop];
//    [recognitionRequest endAudio];
//
//    NSLog(@"audio engine stopped");
//    [self updateText:@"audio engine stopped"];
}


#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability:%d",available);
}

-(void)updateText:(NSString*)string{
    NSString *finalString = [NSString stringWithFormat:@"%@\n%@",self.textView.text,string];
    self.textView.text = finalString;
}

-(void)updateText2:(NSString*)string{
    NSString *finalString = [NSString stringWithFormat:@"%@\n%@",self.commandText.text,string];
    self.commandText.text = finalString;
}


-(void) onlyGetLastWord :(NSString*)result{
    //    https://stackoverflow.com/questions/40843713/remove-the-first-word-in-a-string-continuously-and-keep-the-last-word-xamarin-f
    //    https://stackoverflow.com/questions/23991392/split-string-by-particular-character-ios
    NSString* resultString =result;
    NSLog(@"Result String ::::%@",result);
    
    if(resultString !=nil && [resultString  containsString:@" "] ){
        NSArray *items = [resultString componentsSeparatedByString:@" "];   //take the one array for split the string
        NSLog(@"The array items ::::%@",items);
        resultString = items.lastObject;
        NSLog(@"Last object::::%@",resultString);
        [self updateText:resultString];
        [self voiceCommand:resultString];
    }else{
        [self updateText:resultString];
        [self voiceCommand:resultString];
    }
    
}

-(void) voiceCommand:(NSString *)Commands{
    
    NSString* command =  Commands;
    if([[command lowercaseString]containsString:@"next"] ){
        NSLog(@"Next Operation Performed");
        [self updateText2:@"Next Operation Performed"];
    }else if([[command lowercaseString]containsString:@"back"] ){
        NSLog(@"back Operation Performed");
        [self updateText2:@"back Operation Performed"];
    }else if([[command lowercaseString]containsString:@"boxing"] ){
        NSLog(@"boxing Operation Performed");
        [self updateText2:@"boxing Operation Performed"];
    }else if([[command lowercaseString]containsString:@"again"] ){
        NSLog(@"Play again Operation Performed");
        [self updateText2:@" play again Operation Performed"];
    }else if([[command lowercaseString]containsString:@"start"] ){
        NSLog(@"start Operation Performed");
        [self updateText2:@"start Operation Performed"];
    }else if([[command lowercaseString]containsString:@"stop"] ){
        NSLog(@"stop Operation Performed");
        [self updateText2:@"stop Operation Performed"];
    }else{
        NSLog(@" Voice not recognized properly");
        [self updateText2:@"Voice not recognized properly... "];
    }
    
}

@end
