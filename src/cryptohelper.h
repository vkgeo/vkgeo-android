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

    Q_PROPERTY(QString     encryptionKey         READ encryptionKey         WRITE setEncryptionKey         NOTIFY encryptionKeyChanged)
    Q_PROPERTY(QVariantMap friendsEncryptionKeys READ friendsEncryptionKeys WRITE setFriendsEncryptionKeys NOTIFY friendsEncryptionKeysChanged)

private:
    explicit CryptoHelper(QObject *parent = nullptr);
    ~CryptoHelper() noexcept override = default;

public:
    CryptoHelper(const CryptoHelper &) = delete;
    CryptoHelper(CryptoHelper &&) noexcept = delete;

    CryptoHelper &operator=(const CryptoHelper &) = delete;
    CryptoHelper &operator=(CryptoHelper &&) noexcept = delete;

    static CryptoHelper &GetInstance();

    QString encryptionKey() const;
    void setEncryptionKey(const QString &key);

    QVariantMap friendsEncryptionKeys() const;
    void setFriendsEncryptionKeys(const QVariantMap &keys);

    Q_INVOKABLE void regenerateEncryptionKey();

    Q_INVOKABLE QString getFriendEncryptionKey(const QString &friend_user_id) const;
    Q_INVOKABLE void setFriendEncryptionKey(const QString &friend_user_id, const QString &friend_encryption_key);
    Q_INVOKABLE void removeFriendEncryptionKey(const QString &friend_user_id);
    Q_INVOKABLE void clearFriendsEncryptionKeys();

    std::tuple<QString, QByteArray> EncryptWithAES256CBC(const QString &key, const QByteArray &payload) const;
    QByteArray DecryptAES256CBC(const QString &key, const QString &iv, const QByteArray &encrypted_payload) const;

signals:
    void encryptionKeyChanged(const QString &encryptionKey);
    void friendsEncryptionKeysChanged(const QVariantMap &friendsEncryptionKeys);

private:
    QString GenerateRandomString(int length) const;

    static constexpr int ENCRYPTION_KEY_LENGTH = 32,
                         AES_256_IV_LENGTH     = 16;

    QString     EncryptionKey;
    QVariantMap FriendsEncryptionKeys;
};

#endif // CRYPTOHELPER_H
