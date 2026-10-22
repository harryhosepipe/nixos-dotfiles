# CLIamp 1.63.2 and Jellyfin 12 password authentication

## Finding

The HTTP 400 is caused by an authorization-header incompatibility, not by the
username, password, server address, reverse proxy, or Jellyfin's
`AuthenticateByName` request body.

CLIamp 1.63.2 correctly posts this JSON to
`/Users/AuthenticateByName`:

```json
{"Username":"<user>","Pw":"<password>"}
```

However, it sends the client identity in `X-Emby-Authorization`. Its Jellyfin
dialect describes and implements this explicitly. See CLIamp's
[`ensureAuth`](https://github.com/bjarneo/cliamp/blob/v1.63.2/internal/embyapi/client.go#L583-L608)
and
[`jellyfinDialect.applyAuth`](https://github.com/bjarneo/cliamp/blob/v1.63.2/internal/embyapi/dialect.go#L828-L843).

Jellyfin 12 disables legacy authorization by default. A Jellyfin maintainer
states that the old methods were deprecated starting in 2023, were announced
and made opt-in testable in 10.11, are opt-out in 10.12, and will be removed in
10.13. The first-party report shows the same HTTP 400 symptom when
`EnableLegacyAuthorization=false`:
[jellyfin/jellyfin#15962](https://github.com/jellyfin/jellyfin/issues/15962#issuecomment-3715603585).

The current official Jellyfin TypeScript SDK uses the standard
`Authorization` header, not `X-Emby-Authorization`. It constructs a
`MediaBrowser` value containing client, device, version, and token fields:

- [`AUTHORIZATION_HEADER = 'Authorization'`](https://github.com/jellyfin/jellyfin-sdk-typescript/blob/master/src/constants.ts#L8-L9)
- [`getAuthorizationHeader`](https://github.com/jellyfin/jellyfin-sdk-typescript/blob/master/src/utils/authentication.ts#L8-L18)
- [`authenticateUserByName` sends `Username` and `Pw`](https://github.com/jellyfin/jellyfin-sdk-typescript/blob/master/src/api.ts#L75-L84)

Therefore CLIamp's JSON body matches the official SDK, while its header name
does not.

## Durable fix

Patch CLIamp's Jellyfin dialect to use the modern header and include the
session token in that header after password login:

```go
func (jellyfinDialect) applyAuth(req *http.Request, token, _, deviceID string) {
	req.Header.Set("Authorization",
		fmt.Sprintf(`MediaBrowser Client="%s", Device="%s", DeviceId="%s", Version="%s", Token="%s"`,
			url.QueryEscape(appmeta.ClientName()),
			url.QueryEscape(appmeta.DeviceName()),
			url.QueryEscape(deviceID),
			url.QueryEscape(appmeta.Version()),
			url.QueryEscape(token)))
}
```

At minimum, changing `X-Emby-Authorization` to `Authorization` fixes the
initial username/password request because its token is empty. Including
`Token="..."` is also necessary for the subsequent authenticated requests to
follow the modern Jellyfin format. `X-Emby-Token` should not be relied upon;
it belongs to the legacy path being removed.

The official SDK percent-encodes every field before constructing the header,
so the production patch should do likewise. Go's `url.QueryEscape` is a close
equivalent for these values; a small helper can make this easier to test.

## Tests the package patch should add

1. Password authentication sends `Authorization: MediaBrowser ...` and no
   `X-Emby-Authorization`.
2. The login body remains `{"Username":"...","Pw":"..."}`.
3. The request immediately after login contains `Token="<access token>"` in
   `Authorization`.
4. Client/device/version/token values containing reserved characters are
   encoded.

## Temporary server-side workaround (not recommended)

Setting `<EnableLegacyAuthorization>true</EnableLegacyAuthorization>` in
Jellyfin's `system.xml` would allow CLIamp's old header on Jellyfin 12, but it
is only a bridge: Jellyfin says legacy authorization will be removed in 10.13.
It is therefore inferior to patching CLIamp and does not provide a durable
solution.

## Conclusion

Preserving user-credential authentication requires no change to the user's
Jellyfin credentials. Patch CLIamp 1.63.2's Jellyfin request authentication
from the legacy `X-Emby-Authorization`/`X-Emby-Token` mechanism to the official
`Authorization: MediaBrowser ... Token="..."` format, rebuild the Nix package,
and rerun `cliamp setup` with the existing username and password.
