#ifndef CRYPTOHELPER_H
#define CRYPTOHELPER_H

#include <tuple>

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QByteArray>
#include <QtCore/QVariantMap>

class CryptoHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString     sharedKey           READ sharedKey           WRITE setSharedKey           NOTIFY sharedKeyChanged)
    Q_PROPERTY(QVariantMap sharedKeysOfFriends READ sharedKeysOfFriends WRITE setSharedKeysOfFriends NOTIFY sharedKeysOfFriendsChanged)

private:
    explicit CryptoHelper(QObject *parent = nullptr);
    ~CryptoHelper() noexcept override = default;

public:
    CryptoHelper(const CryptoHelper &) = delete;
    CryptoHelper(CryptoHelper &&) noexcept = delete;

    CryptoHelper &operator=(const CryptoHelper &) = delete;
    CryptoHelper &operator=(CryptoHelper &&) noexcept = delete;

    static CryptoHelper &GetInstance();

    QString sharedKey() const;
    void setSharedKey(const QString &key);

    QVariantMap sharedKeysOfFriends() const;
    void setSharedKeysOfFriends(const QVariantMap &keys);

    Q_INVOKABLE void regenerateSharedKey();

    Q_INVOKABLE QString getSharedKeyOfFriend(const QString &friend_user_id) const;
    Q_INVOKABLE void setSharedKeyOfFriend(const QString &friend_user_id, const QString &friend_key);
    Q_INVOKABLE void removeSharedKeyOfFriend(const QString &friend_user_id);
    Q_INVOKABLE void clearSharedKeysOfFriends();

    std::tuple<QString, QByteArray> EncryptWithAES256CBC(const QString &key, const QByteArray &payload) const;
    QByteArray DecryptAES256CBC(const QString &key, const QString &iv, const QByteArray &encrypted_payload) const;

signals:
    void sharedKeyChanged(const QString &sharedKey);
    void sharedKeysOfFriendsChanged(const QVariantMap &sharedKeysOfFriends);

private:
    QString GenerateRandomString(int length) const;

    static constexpr int SHARED_KEY_LENGTH = 32,
                         AES_256_IV_LENGTH = 16;

    QString     SharedKey;
    QVariantMap SharedKeysOfFriends;
};

#endif // CRYPTOHELPER_H
