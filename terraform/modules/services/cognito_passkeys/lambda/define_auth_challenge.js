exports.handler = (event, context, callback) => {
  console.log(event);
  console.log(context);

  const latest_session = parse_session(event);
  if (latest_session == null) {
    callback(null, auth_challenge(event, "CUSTOM_CHALLENGE"))
  } else if (
    latest_session.challengeName === "CUSTOM_CHALLENGE" &&
    latest_session.challengeResult === true
  ) {
    event = auth_success(event);
  } else if (latest_session.challengeName === "SRP_A") {
    event = auth_challenge(event, "PASSWORD_VERIFIER");
  } else {
    event = auth_challenge(event, "CUSTOM_CHALLENGE");
  }

  // Return to Amazon Cognito
  callback(null, event);
};

const parse_session = (event) => {
  // If user is not registered
  if (event.request.userNotFound) {
    throw new Error("User does not exist");
  }

  const sessions = event.request?.session;

  if (!sessions || !sessions.length) {
    return null;
  }

  const latest_session = sessions.slice(-1)[0];

  if (sessions.length >= 5 && latest_session.challengeResult === false) {
    throw new Error("Invalid credentials");
  }
  return latest_session;
};

const auth_success = (event) => {
  event.response.issueTokens = true;
  event.response.failAuthentication = false;
  return event;
};

const auth_challenge = (event, challenge) => {
  event.response.issueTokens = false;
  event.response.failAuthentication = false;
  event.response.challengeName = challenge;
  return event;
};
