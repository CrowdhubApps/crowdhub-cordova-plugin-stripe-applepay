var exec = require("cordova/exec");

let executeCallback = function (callback, message) {
  if (typeof callback === "function") {
    callback(message);
  }
};

exports.canMakePayments = function (success, error) {
  return new Promise(function (resolve, reject) {
    exec(
      function (message) {
        executeCallback(success, message);
        resolve(message);
      },
      function (message) {
        executeCallback(error, message);
        reject(message);
      },
      "CDVStripeApplePay",
      "canMakePayments",
      []
    );
  });
};

exports.makePaymentRequest = function (order, success, error) {
  return new Promise(function (resolve, reject) {
    exec(
      function (message) {
        executeCallback(success, message);
        resolve(message);
      },
      function (message) {
        executeCallback(error, message);
        reject(message);
      },
      "CDVStripeApplePay",
      "makePaymentRequest",
      [order]
    );
  });
};

exports.completeLastTransaction = function (status, success, error) {
  return new Promise(function (resolve, reject) {
    exec(
      function (message) {
        executeCallback(success, message);
        resolve(message);
      },
      function (message) {
        executeCallback(error, message);
        reject(message);
      },
      "CDVStripeApplePay",
      "completeLastTransaction",
      [status]
    );
  });
};
