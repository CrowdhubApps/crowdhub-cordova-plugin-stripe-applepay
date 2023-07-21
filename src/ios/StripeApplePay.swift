import StripeApplePay
import PassKit

@objc(CDVStripeApplePay)
class CDVStripeApplePay : CDVPlugin, ApplePayContextDelegate {
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeCore.StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping StripeApplePay.STPIntentClientSecretCompletionBlock) {
        <#code#>
    }
    
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCompleteWith status: StripeApplePay.STPApplePayContext.PaymentStatus, error: Error?) {
        <#code#>
    }
    
    var commandCallback: String?

    override init() {
        #if DEBUG
        StripeAPI.defaultPublishableKey = object(forInfoDictionaryKey: StripeLivePublishableKey)
        #else
        StripeAPI.defaultPublishableKey = object(forInfoDictionaryKey: StripeTestPublishableKey)
        #endif
    }
    
    @objc(canMakePayments:)
    func canMakePayments(command: CDVInvokedUrlCommand) {
        let good = StripeAPI.deviceSupportsApplePay()
        var result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: [])
        if(good){
            result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [])
        }
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }

    @objc(makePaymentRequest:)
    func makePaymentRequest(command: CDVInvokedUrlCommand) {
        
        let country = "US"
        let currency = "USD"
        let merchantIdentifier = "merchant.app2.readmyrhythm.com"
        let label = "RMR Thing"
        let amount = 9.99
        
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: country, currency: currency)

        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount)),
        ]
        
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            // There is a problem with your Apple Pay configuration
        }
        
        func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
            print(paymentMethod.id)
        }

        func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
              switch status {
            case .success:
                // Payment succeeded, show a receipt view
                break
            case .error:
                // Payment failed, show the error
                break
            case .userCancellation:
                // User canceled the payment
                break
            @unknown default:
                fatalError()
            }
        }
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs :[])
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }

    @objc(completeLastTransaction:)
    func completeLastTransaction(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs :[])
        self.commandDelegate.send(result, callbackId: command.callbackId)
        return
    }
}
