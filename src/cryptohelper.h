#ifndef CRYPTOHELPER_H
#define CRYPTOHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QByteArray>
#include <QtCore/QVariantMap>

class CryptoHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString     publicKey           READ publicKey           WRITE setPublicKey           NOTIFY publicKeyChanged)
    Q_PROPERTY(QString     privateKey          READ privateKey          WRITE setPrivateKey          NOTIFY privateKeyChanged)
    Q_PROPERTY(QVariantMap publicKeysOfFriends READ publicKeysOfFriends WRITE setPublicKeysOfFriends NOTIFY publicKeysOfFriendsChanged)

private:
    explicit CryptoHelper(QObject *parent = nullptr);
    ~CryptoHelper() noexcept override = default;

public:
    CryptoHelper(const CryptoHelper &) = delete;
    CryptoHelper(CryptoHelper &&) noexcept = delete;

    CryptoHelper &operator=(const CryptoHelper &) = delete;
    CryptoHelper &operator=(CryptoHelper &&) noexcept = delete;

    static CryptoHelper &GetInstance();

    QString publicKey() const;
    void setPublicKey(const QString &key);

    QString privateKey() const;
    void setPrivateKey(const QString &key);

    QVariantMap publicKeysOfFriends() const;
    void setPublicKeysOfFriends(const QVariantMap &keys);

    Q_INVOKABLE bool validateKeyPair(const QString &public_key, const QString &private_key) const;
    Q_INVOKABLE void regenerateKeyPair();

    Q_INVOKABLE QString getPublicKeyOfFriend(const QString &friend_user_id) const;
    Q_INVOKABLE void setPublicKeyOfFriend(const QString &friend_user_id, const QString &friend_key);
    Q_INVOKABLE void removePublicKeyOfFriend(const QString &friend_user_id);
    Q_INVOKABLE void clearPublicKeysOfFriends();

    QByteArray EncryptWithCryptoBox(const QString &public_key, const QByteArray &payload) const;
    QByteArray DecryptCryptoBox(const QString &public_key, const QString &private_key, const QByteArray &encrypted_payload) const;

signals:
    void publicKeyChanged(const QString &publicKey);
    void privateKeyChanged(const QString &privateKey);
    void publicKeysOfFriendsChanged(const QVariantMap &publicKeysOfFriends);

private:
    QString     PublicKey, PrivateKey;
    QVariantMap PublicKeysOfFriends;
};

#endif // CRYPTOHELPER_H
