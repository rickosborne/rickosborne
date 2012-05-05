//
//  CrudFormView.h
//  Gateways
//
//  Created by rosborne on 4/26/12.
//

#import <UIKit/UIKit.h>

typedef enum
{
	FormInputId = 1,
	FormInputValue,
	FormInputSubmit,
	FormInputDelete
} CreateFormInputs;

@class CrudFormView;

@protocol CrudFormViewControllerDelegate <NSObject>

- (void)formViewController:(CrudFormView *)controller didCollect:(NSDictionary *)data;
- (void)formViewController:(CrudFormView *)controller shouldRemove:(NSDictionary *)data;

@end

@interface CrudFormView : UIViewController
{
	NSMutableDictionary *data;
	@private
	NSMutableDictionary *keyForTag;
}

@property (nonatomic, weak) id <CrudFormViewControllerDelegate> delegate;

- (void)setData:(NSDictionary *)dictionary;

@end
