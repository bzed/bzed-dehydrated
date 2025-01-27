# Match ssh URLs for git
type Dehydrated::GitSSHUrl = Pattern[/(?i:^(ssh:\/\/([^\/@]+@)?[^\/]+\/.*|([^@:]+@)?[^:]+:.*))/]
