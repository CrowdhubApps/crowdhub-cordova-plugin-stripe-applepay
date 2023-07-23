Add your Stripe keys to your config.xml file

```xml
<edit-config file="*-Info.plist" mode="merge" target="StripeLivePublishableKey">
<string>pk_live_your_key_here</string>
</edit-config>
<edit-config file="*-Info.plist" mode="merge" target="StripeTestPublishableKey">
<string>pk_test_your_key_here</string>
</edit-config>
<edit-config file="*-Info.plist" mode="merge" target="MerchantIdentifier">
<string>your.merchant.identifier.here</string>
</edit-config>
```

Make sure to set a debug flag in your Swift Compiler - Custom Flags section of your Build Settings. Add -DDEBUG to Other Swift Flags. This will ensure during development you are using the test keys and not the live keys.

Make sure your ApplePay and Stripe certs are up to date, here is how to create them:
https://support.stripe.com/questions/enable-apple-pay-on-your-stripe-account#:~:text=To%20set%20up%20Apple%20Pay,setup%20process%20will%20be%20different.
