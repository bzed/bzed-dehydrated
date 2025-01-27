# Valid challenge types for letsencrypt
type Dehydrated::Challengetype = Pattern[/^(http-01|dns-01|tls-alpn-01)$/]
