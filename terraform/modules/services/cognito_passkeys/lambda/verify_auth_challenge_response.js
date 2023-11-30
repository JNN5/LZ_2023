const crypto = require("crypto");
const { Fido2Lib } = require('fido2-lib');

const CRYPTO_ALGOTRYTHMS = [-7, -257];

const f2l = new Fido2Lib({
    timeout: 30 * 1000 * 60,
    //rpId: "localhost",
    rpName: 'WebAuthn With Cognito',
    challengeSize: 32,
    cryptoParams: CRYPTO_ALGOTRYTHMS,
  });

exports.handler = async (event) => {
    console.log(event);
    
    const publicKeyPem = await parsePublicKeyCred(event);
    const challengeAnswerJSON = JSON.parse(event.request.challengeAnswer);
    
    const isValidSignature = Boolean(await validateAssertionSignature(publicKeyPem, challengeAnswerJSON));
    console.log("Verification Results:"+isValidSignature);

    return formatToOutput(event, isValidSignature);
};

function formatToOutput(event, isValidSignature) {
    return {
        ...event,
        response: {
            ...event.response,
            answerCorrect: isValidSignature
        }
    };
}

async function parsePublicKeyCred(event) {
    const publicKeyCred = event.request.userAttributes["custom:public_key_cred"];
    const publicKeyCredJSON = JSON.parse(Buffer.from(publicKeyCred, 'base64').toString('ascii'));
    console.log("publicKeyCredJSON", publicKeyCredJSON)
    const { origin } = JSON.parse(Buffer.from(publicKeyCredJSON.response.clientDataJSON, 'base64').toString('ascii'))
    const regResult = await f2l.attestationResult({...publicKeyCredJSON, id: toArrayBuffer(publicKeyCredJSON.id, "id")}, {
        challenge: publicKeyCredJSON.challenge,
        origin,
        factor: "either"
      });
    console.log("regResult", regResult)
    return regResult.authnrData.get("credentialPublicKeyPem");
}

async function validateAssertionSignature(publicKeyPem, challengeAnswerJSON) {
    
    let expectedSignature = toArrayBuffer(challengeAnswerJSON.response.signature, "signature");
    let publicKey = publicKeyPem;
    let rawAuthnrData = toArrayBuffer(challengeAnswerJSON.response.authenticatorData, "authenticatorData");
    let rawClientData = toArrayBuffer(challengeAnswerJSON.response.clientDataJSON, "clientDataJSON");

    const hash = crypto.createHash("SHA256");
    hash.update(Buffer.from(new Uint8Array(rawClientData)));
    let clientDataHashBuf = hash.digest();
    let clientDataHash = new Uint8Array(clientDataHashBuf).buffer;

    const verify = crypto.createVerify("SHA256");
    verify.write(Buffer.from(new Uint8Array(rawAuthnrData)));
    verify.write(Buffer.from(new Uint8Array(clientDataHash)));
    verify.end();
    

    try {
        return verify.verify(publicKey, Buffer.from(new Uint8Array(expectedSignature)));
    } catch (e) {
        console.error(e); 
        return false;
    }

}

function toArrayBuffer(buf, name) {
    if (!name) {
        throw new TypeError("name not specified");
    }

    if (typeof buf === "string") {
        buf = buf.replace(/-/g, "+").replace(/_/g, "/");
        buf = Buffer.from(buf, "base64");
    }

    if (buf instanceof Buffer || Array.isArray(buf)) {
        buf = new Uint8Array(buf);
    }

    if (buf instanceof Uint8Array) {
        buf = buf.buffer;
    }

    if (!(buf instanceof ArrayBuffer)) {
        throw new TypeError(`could not convert '${name}' to ArrayBuffer`);
    }

    return buf;
}