# Age Rating Questionnaire

App Store Connect fills this in via a questionnaire (not a pasteable text
field) — these are the answers to give, with the reasoning behind each,
verified against the actual codebase (no network calls, no UGC, no third-party
SDKs beyond RxSwift). Expected result: **4+**.

| Category | Answer | Why |
|---|---|---|
| Cartoon or Fantasy Violence | None | No violence of any kind |
| Realistic Violence | None | — |
| Prolonged Graphic or Sadistic Realistic Violence | None | — |
| Profanity or Crude Humor | None | All copy is child-directed encouragement text |
| Mature/Suggestive Themes | None | — |
| Horror/Fear Themes | None | — |
| Medical/Treatment Information | None | — |
| Alcohol, Tobacco, or Drug Use or References | None | — |
| Simulated Gambling | None | — |
| Sexual Content or Nudity | None | — |
| Graphic Sexual Content and Nudity | None | — |
| Contests | None | No contests or sweepstakes |
| Gambling and Contests | None | — |
| Unrestricted Web Access | No | Confirmed: no `URLSession`/network code anywhere in the app |
| User-Generated Content / messaging | No | No accounts, no chat, no sharing, no UGC of any kind |
| Advertising / Third-Party Analytics | No | No ad SDK, no analytics SDK — RxSwift is the only dependency and does neither |

With every category at "None"/"No", App Store Connect should compute **4+**
automatically. If any answer needs to change later (e.g. a future feature
adds web access), revisit this table and update it alongside the code change
that caused it.
