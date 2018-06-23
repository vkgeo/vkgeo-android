#import <UserNotifications/UNUserNotificationCenter.h>
#import <UserNotifications/UNNotificationSettings.h>
#import <UserNotifications/UNNotificationSound.h>
#import <UserNotifications/UNNotificationContent.h>
#import <UserNotifications/UNNotificationRequest.h>

#include <QtCore/QDebug>

#include "notificationhelper.h"

NotificationHelper::NotificationHelper(QObject *parent) : QObject(parent)
{
    Initialized = false;
}

NotificationHelper::~NotificationHelper()
{
}

void NotificationHelper::initialize()
{
    if (!Initialized) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionSound)
                                                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            Q_UNUSED(granted)

            if (error != nil) {
                qWarning() << QString::fromNSString([error localizedDescription]);
            }
        }];

        Initialized = true;
    }
}

void NotificationHelper::showNotification(QString id, QString title, QString body)
{
    if (Initialized) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                UNMutableNotificationContent *content = [[[UNMutableNotificationContent alloc] init] autorelease];

                content.title = title.toNSString();
                content.body  = body.toNSString();
                content.sound = [UNNotificationSound defaultSound];

                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:id.toNSString() content:content trigger:nil];

                [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error != nil) {
                        qWarning() << QString::fromNSString([error localizedDescription]);
                    }
                }];
            }
        }];
    }
}
