import Stripe
import PassKit

@objc(CDVStripeApplePay)
class CDVStripeApplePay : CDVPlugin, PKPaymentAuthorizationControllerDelegate {

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

        guard let merchantIdentifier = infoDictionary?["MerchantIdentifier"] as? String else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no MerchantIdentifier in your plist."])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

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
        
        /*
         items: [
             {
                 label: '3 x Basket Items',
                 amount: 49.99
             },
             {
                 label: 'Next Day Delivery',
                 amount: 3.99
             },
                     {
                 label: 'My Fashion Company',
                 amount: 53.98
             }
         ],
         shippingMethods: [
             {
                 identifier: 'NextDay',
                 label: 'NextDay',
                 detail: 'Arrives tomorrow by 5pm.',
                 amount: 3.99
             },
             {
                 identifier: 'Standard',
                 label: 'Standard',
                 detail: 'Arrive by Friday.',
                 amount: 4.99
             },
             {
                 identifier: 'SaturdayDelivery',
                 label: 'Saturday',
                 detail: 'Arrive by 5pm this Saturday.',
                 amount: 6.99
             }
         ],
         currencyCode: 'GBP',
         countryCode: 'GB'
         billingAddressRequirement: 'none',
         shippingAddressRequirement: 'none',
         shippingType: 'shipping'
         */
        
        let label = "RMR Thing"
        let amount = 9.99
        
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount)),
        ]
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = [.name]
        paymentRequest.requiredBillingContactFields = [.name]
        paymentRequest.supportedNetworks = [.amex, .discover, .masterCard, .visa, .maestro]
        paymentRequest.shippingType = shippingTypePK
        paymentRequest.shippingMethods = []
        
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        paymentController.present(completion: nil)
        
    }

    @objc(completeLastTransaction:)
    func completeLastTransaction(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs :[])
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }
    
    internal func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler: @escaping (PKPaymentAuthorizationResult) -> Void) {
        let infoDictionary = Bundle.main.infoDictionary
        
        #if DEBUG
        guard let publishableKey = infoDictionary?["StripeTestPublishableKey"] as? String else {
            print("There is no StripeTestPublishableKey in your plist")
//            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no StripeTestPublishableKey in your plist"])
//            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        #else
        guard let publishableKey = infoDictionary?["StripeLivePublishableKey"] as? String else {
            print("There is no StripeTestPublishableKey in your plist")
//            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs :["There is no StripeLivePublishableKey in your plist"])
//            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        #endif
        STPAPIClient.shared.publishableKey = publishableKey
        var stripePaymentMethod: String?
        STPAPIClient.shared.createSource(with: payment, completion: {paymentMethod,error in
            print(error?.localizedDescription as Any)
            stripePaymentMethod = paymentMethod?.stripeID
            print(stripePaymentMethod ?? "no payment id created")
        })
        
        // Process the payment on your server, and call the completion handler accordingly
        // Use the payment.token to send payment information securely to your server
        // After processing, call the completion handler with a result status
        handler(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    internal func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }
    
}
