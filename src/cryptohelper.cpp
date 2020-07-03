#include <QtCore/QLatin1String>
#include <QtCore/QDebug>

#include <qrsaencryption.h>

#include "cryptohelper.h"

CryptoHelper::CryptoHelper(QObject *parent) :
    QObject(parent)
{
}

CryptoHelper &CryptoHelper::GetInstance()
{
    static CryptoHelper instance;

    return instance;
}

QString CryptoHelper::publicKey() const
{
    return PublicKey;
}

void CryptoHelper::setPublicKey(const QString &key)
{
    if (PublicKey != key) {
        PublicKey = key;

        emit publicKeyChanged(PublicKey);
    }
}

QString CryptoHelper::privateKey() const
{
    return PrivateKey;
}

void CryptoHelper::setPrivateKey(const QString &key)
{
    if (PrivateKey != key) {
        PrivateKey = key;

        emit privateKeyChanged(PrivateKey);
    }
}

QVariantMap CryptoHelper::publicKeysOfFriends() const
{
    return PublicKeysOfFriends;
}

void CryptoHelper::setPublicKeysOfFriends(const QVariantMap &keys)
{
    if (PublicKeysOfFriends != keys) {
        PublicKeysOfFriends = keys;

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

bool CryptoHelper::validateKeyPair(const QString &public_key, const QString &private_key) const
{
    const QByteArray test_payload("TEST PAYLOAD FOR KEY PAIR VALIDATION");

    QRSAEncryption rsa(QRSAEncryption::Rsa::RSA_2048);

    return rsa.decode(rsa.encode(test_payload, QByteArray::fromBase64(public_key.toUtf8())),
                      QByteArray::fromBase64(private_key.toUtf8())) == test_payload;
}

void CryptoHelper::regenerateKeyPair()
{
    QRSAEncryption rsa(QRSAEncryption::Rsa::RSA_2048);

    QByteArray raw_public_key, raw_private_key;

    if (rsa.generatePairKey(raw_public_key, raw_private_key)) {
        QString public_key  = QString::fromUtf8(raw_public_key.toBase64());
        QString private_key = QString::fromUtf8(raw_private_key.toBase64());

        if (PublicKey != public_key) {
            PublicKey = public_key;

            emit publicKeyChanged(PublicKey);
        }
        if (PrivateKey != private_key) {
            PrivateKey = private_key;

            emit privateKeyChanged(PrivateKey);
        }
    } else {
        qWarning() << "regenerateKeyPair() : QRSAEncryption::generatePairKey() failed";
    }
}

QString CryptoHelper::getPublicKeyOfFriend(const QString &friend_user_id) const
{
    if (PublicKeysOfFriends.contains(friend_user_id)) {
        return PublicKeysOfFriends[friend_user_id].toString();
    } else {
        return QLatin1String("");
    }
}

void CryptoHelper::setPublicKeyOfFriend(const QString &friend_user_id, const QString &friend_key)
{
    if (friend_user_id != QLatin1String("") && (!PublicKeysOfFriends.contains(friend_user_id) ||
                                                 PublicKeysOfFriends[friend_user_id] != friend_key)) {
        PublicKeysOfFriends[friend_user_id] = friend_key;

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

void CryptoHelper::removePublicKeyOfFriend(const QString &friend_user_id)
{
    if (PublicKeysOfFriends.contains(friend_user_id)) {
        PublicKeysOfFriends.remove(friend_user_id);

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

void CryptoHelper::clearPublicKeysOfFriends()
{
    if (!PublicKeysOfFriends.isEmpty()) {
        PublicKeysOfFriends.clear();

        emit publicKeysOfFriendsChanged(PublicKeysOfFriends);
    }
}

QByteArray CryptoHelper::EncryptWithRSA(const QByteArray &public_key, const QByteArray &payload) const
{
    QRSAEncryption rsa(QRSAEncryption::Rsa::RSA_2048);

    return rsa.encode(payload, public_key);
}

QByteArray CryptoHelper::DecryptRSA(const QByteArray &private_key, const QByteArray &encrypted_payload) const
{
    QRSAEncryption rsa(QRSAEncryption::Rsa::RSA_2048);

    return rsa.decode(encrypted_payload, private_key);
}
