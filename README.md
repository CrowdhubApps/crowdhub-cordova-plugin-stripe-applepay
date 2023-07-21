Add your Stripe keys to your config.xml file

```xml
<edit-config file="*-Info.plist" mode="merge" target="StripeLivePublishableKey">
<string>pk_live_your_key_here</string>
</edit-config>
<edit-config file="*-Info.plist" mode="merge" target="StripeTestPublishableKey">
<string>pk_test_your_key_here</string>
</edit-config>
```
