# FireFlair prototype — changelog

## v16.1 — 2026-10-08 — Join the Team profile, WhatsApp sign-up, Save & Share, Section 5, invited-by Network
Artifact version 1791497422-8086 · file `fireflair-v16.1.html`

Everything since v16, in one release.

Profile page — "Join the Team"
- Section 1 is the account: FF Tag + phone number -> Continue -> WhatsApp code -> Create. The account exists once the code is verified.
- Optional password pop-up straight after ("Create a password?" / Skip for now). Without one, people sign in with a WhatsApp code.
- FF Tag is now a username: 3 to 8 letters or numbers, unique, not case sensitive, stored lower case (alex, alexg, alex94). It's suggested from the person's name, shown after "ffparty.uk/" with a live available/taken tick, and can be changed later (Section 1, or "FF Tag & sign-in" in the account menu). The placeholder is /username.
- Log in opens on "WhatsApp code"; password is the second option.
- Short headings, far less explanatory text: 1 Join the Team, 2 Profile Card, 3 FF AI & CV, 4 Your profile, then Save & Share, then Section 5.
- The profile saves itself once the account exists (no "Save your Profile Card" section).
- Save & Share replaces Save & Publish. Save is the explicit "done". Share sends the card to the person's own WhatsApp and turns their card link on.
- Section 5 sits under Save & Share, closed (its number, a short line and three dashes running down). Save opens it: "Welcome to the Team" + the finished Profile Card + an Add button.
- Add (the FF mark, also in the header) = "Share your card": type someone's phone number and send them your card.

Network
- A new user starts with one connection: the person who invited them, labelled "Invited you". Prototype: everyone arrives on Don Gee's link (DONGE). Tapping Join on someone's profile before having an account makes that person the inviter instead.

Cards
- Reorder controls are clear left/right arrows: <- 1 ->
- The decorative circle between the card type and the title is gone.
- Media cards: title at the top, the media fills the rest, no description.
- Question cards: question on the top half, answer on the bottom half in larger type.

Look and feel
- Have a CV?: pale burgundy box with a burgundy button before upload; after upload it stays on the page in a calm neutral state with Replace.
- Pick your professions uses the FireFlair gold, with dark text and burgundy for chosen professions.
- Profile photo control: camera with a + in the small circle on the card. The microphone is drawn into the page. The icon library now loads from a second source if the first doesn't arrive.
- Real map (Leaflet) on Home and Network.

For the developers — what Core needs to provide (all mocked here, nothing is sent):
- AUTH_ADAPTER: suggestTag, isAvailable, sendSignupCode, verifySignupCode (this creates the account), setPassword, changeTag, loginWithPassword, sendCode/verifyCode (WhatsApp log-in).
- PROFILE_ADAPTER: save (auto-save and the Save button), share (card to the person's own WhatsApp), shareTo (card to someone else's number).
- Invites: the inviter comes from the link's tag (INVITE_LINK_TAG in the prototype) or from Join on a profile.


