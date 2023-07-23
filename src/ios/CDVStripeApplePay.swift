import Stripe
import PassKit

struct ShippingMethod {
    var amount: NSDecimalNumber
    var label: String
}

struct Item {
    var amount: NSDecimalNumber
    var label: String
}

@objc(CDVStripeApplePay)
class CDVStripeApplePay : CDVPlugin, PKPaymentAuthorizationControllerDelegate {
    var paymentRequestCallbackId: String?
    var pkItems: [Item]?

    @objc(canMakePayments:)
    func canMakePayments(command: CDVInvokedUrlCommand) {
        let deviceSupports = StripeAPI.deviceSupportsApplePay()
        let canPay = PKPaymentAuthorizationViewController.canMakePayments()
        var result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: [])
        if(!deviceSupports){
            result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "This device does not support Apple Pay")
        } else if (!canPay){
            result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Apple Pay does not have a valid payment method")
        } else {
            result = CDVPluginResult(status: CDVCommandStatus_OK)
        }
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }

    @objc(makePaymentRequest:)
    func makePaymentRequest(command: CDVInvokedUrlCommand) {
        let infoDictionary = Bundle.main.infoDictionary
        
        #if DEBUG
        guard let publishableKey = infoDictionary?["StripeTestPublishableKey"] as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no StripeTestPublishableKey in your plist"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        #else
        guard let publishableKey = infoDictionary?["StripeLivePublishableKey"] as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no StripeLivePublishableKey in your plist"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        #endif
        
        STPAPIClient.shared.publishableKey = publishableKey
        
        guard let merchantIdentifier = infoDictionary?["MerchantIdentifier"] as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no MerchantIdentifier in your plist."])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        STPAPIClient.shared.configuration.appleMerchantIdentifier = merchantIdentifier

        guard let args = command.arguments[0] as? NSDictionary else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["This call did not contain any arguments."])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        guard let countryCode = args.value(forKey:"countryCode") as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["This call did not contain a country code"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        guard let currencyCode = args.value(forKey:"currencyCode") as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["This call did not contain a currency code"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
         var shippingTypePK: PKShippingType
         let shippingType = args.value(forKey:"shippingType") as? String
        
         switch shippingType {
             case "shipping":
                 shippingTypePK = PKShippingType.shipping
             case "delivery":
                 shippingTypePK = PKShippingType.delivery
             case "store":
                 shippingTypePK = PKShippingType.storePickup
             case "service":
                 shippingTypePK = PKShippingType.servicePickup
             default:
                 shippingTypePK = PKShippingType.shipping
         }
        
        guard let items = args.value(forKey:"items") as? [NSDictionary] else {
            print(args.value(forKey:"items"))
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: ["This call did not contain any items"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        let paymentRequest = PKPaymentRequest()
        for item in items {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: item["label"] as! String, amount: NSDecimalNumber(decimal: (item["amount"] as! NSNumber).decimalValue)))
        }
        
        if let shippingMethods = args.value(forKey: "shippingMethods") as? [NSDictionary] {
            for sm in shippingMethods {
                paymentRequest.shippingMethods?.append(PKShippingMethod(label: sm["label"] as! String, amount: NSDecimalNumber(decimal: (sm["amount"] as! NSNumber).decimalValue)))
            }
        }
        
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = [.name]
        paymentRequest.requiredBillingContactFields = [.name]
        paymentRequest.supportedNetworks = [.amex, .discover, .masterCard, .visa, .maestro]
        paymentRequest.shippingType = shippingTypePK
        
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        
        self.paymentRequestCallbackId = command.callbackId
        paymentController.present(completion: {_ in
            self.pkItems?.removeAll()
        })
    }

    @objc(completeLastTransaction:)
    func completeLastTransaction(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs :["Not implemented"])
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }
    
    internal func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler: @escaping (PKPaymentAuthorizationResult) -> Void) {
        var pkAuthResult: PKPaymentAuthorizationStatus = .success
        var pkErrors: [Error] = []
        
        STPAPIClient.shared.createToken(with: payment) { (token, error) in
            
            if error != nil {
                print(error.debugDescription as Any)
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error?.localizedDescription)
                self.commandDelegate.send(result, callbackId: self.paymentRequestCallbackId)
                pkAuthResult = .failure
                pkErrors.append(error!)
                self.paymentRequestCallbackId = nil
            } else {
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["stripeToken": token?.tokenId as Any])
                self.commandDelegate.send(result, callbackId: self.paymentRequestCallbackId)
                pkAuthResult = .success
                self.paymentRequestCallbackId = nil
            }
        }

        
        handler(PKPaymentAuthorizationResult(status: pkAuthResult, errors: pkErrors))
    }
    
    internal func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }
    
}
