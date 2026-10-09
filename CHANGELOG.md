# FireFlair prototype — changelog

## v16.5 — 2026-10-09 — FF AI reads CVs: extraction + review
Artifact version 1791552281-a5e0 · file `fireflair-v16.5.html`

FF AI now really reads a CV (PDF, Word, a photo or text) — every page — and turns it into editable profile suggestions. Nothing is saved until the person adds it.

Why
- The old FF AI was a keyword matcher (profileFromText) and the CV adapter was a mock that always said "not connected". That is why interests, descriptions and job history were missed and only a handful of items came back.

Pipeline (section 4, SERVICES — FF AI profile extraction)
- CV_READER.read(file): PDFs through pdf.js (pdfjs-dist 6.2.108, legacy build, loaded from jsDelivr only when a PDF is read; parsed on the page, no Worker). Text page by page in reading order, sections kept; each page is also pictured for the AI (layout, columns, scans); pictures inside the PDF are found from the drawing operations and cropped as possible profile photos. Word (.docx) is unzipped in the browser (DecompressionStream) — paragraphs, headings, bullets, tables, text boxes, headers/footers and embedded pictures. Photos of CVs go to the AI as pictures (it reads them). Text files as text. Old .doc and unknown types get a clear message.
- CV_ADAPTER.extract(doc): two FF AI calls run side by side (work history; profile details), each with the whole CV. The CV is wrapped as untrusted data and the prompt forbids following anything written inside it. Typed "Tell us about yourself" text uses one call.
- In this prototype FF AI is Claude through the artifact's `sample` capability (the viewer's own Claude account; no key in the page). The artifact now declares `sample` alongside `db`.
- validateExtraction(): every item is checked against the schema (category, title, description, evidence, confidence, page, proficiency, details: employer, location, start, end, venues, level, issuer, group). Failures are counted and listed, never silently dropped.
- buildSuggestions(): semantic de-duplication (case, punctuation, &/and, plurals, word order, bracketed notes) inside the result and against the profile. Distinct activities stay distinct (Running is not Marathon Running).
- extractionReport(): what was read, statuses (extracted, needs confirmation, unreadable, rejected by validation, duplicates merged, already on profile, failures), per-category counts, timings. Logged to the console as "[FF AI] extraction report" and shown under "How FF AI read this".

Review (ExtractionReview, used by both FF AI and the CV panel)
- Replaces "Found N things": "FF AI found N suggestions" where N is exactly what is listed. Grouped by category with counts and Tick all / Untick all; every item can be ticked, edited (title, employer, location, dates, level, description, and where it's saved) or removed. Employment shows employer · place · dates, freelance shows its venues, each item shows the CV quote it came from, and anything not clearly stated is marked "Check this".
- Proposed profile photo: preview, drag to move, zoom to crop, "Not me". Ticked only when the profile has no photo; otherwise it says it would replace the current one and stays unticked.
- Name (only when the profile has none) and the CV's personal summary as About.
- Things already on the profile are listed separately; if FF AI found details a card is missing, it can fill those EMPTY fields only (new RECORDS_FILL action). RECORDS_MERGE now uses the same semantic match so it never adds a near-duplicate card.
- When FF AI isn't available in a view (or the viewer declines), the old matcher is used and the review says so plainly.
- Progress with Stop; clear messages and a manual Try again for busy, failed or unreadable documents; a scanned CV in a view that can't send pictures is told so rather than returning nothing.

Profile
- New About section (profile.about) at the top of the profile, editable; shown on public profiles too.
- Information Cards show the CV details line (employer · place · dates, or a language's level as written); the card sheet shows and edits those details (record.details, with details.type = employment / freelance / education / achievement …). Venues get their location as the address.
- CV panel: "FF AI fills in your profile from it — PDF, Word or a photo." After upload FF AI starts reading; a saved CV has "Read with FF AI".

Tested in the built page (headless Chromium, phone and desktop)
- A synthetic two-page CV (7 jobs, freelance section with venues, interests in the summary and closing lines, WSET Level 2, flair courses, Romanian + English, education, portrait + logo) as PDF, Word and a photo; prompts recorded from the app and answered by a stand-in Claude, then replayed through the app: all 17 checks pass (all 7 jobs with details, freelance + venues, all 10 interests incl. Ironman goal, WSET, courses, languages with levels, education, About). Adding twice creates no duplicate cards and never overwrites an edit.
- Failure cases pass: FF AI absent or declined (fallback, labelled), busy (message + manual retry, no automatic retries), one call failing (partial result, flagged), Stop, picture-only CV without vision, damaged PDF, invalid items rejected and counted, oversized document cut to fit and flagged.
- Not testable from here: live FF AI answers in the published page (needs the viewer's consent), and the real Alexandru Gavrilas CV (not received yet).

Backend
- FireFlair-Backend gets the same contract on OpenAI as a separate pull request for Griffy (key in Render's environment only).

## v16.4 — 2026-10-09 — Q&A: green answered cards, two sides, shuffled
Artifact version 1791549316-6309 · file `fireflair-v16.4.html`

Q&A section: answered questions feel like an achievement, sit on their own side, and the order changes each visit.

Answered state
- Answered Question Cards turn green (QUESTION_DONE colours) with a green outline and a large green tick badge top-right, replacing the small tick.
- Answering a question for the first time plays a completion animation on that card: the card pops, a large green disc draws a tick, a ring pulses out with a few gold sparks (about 1.5s). Editing an existing answer doesn't replay it. Reduced-motion settings switch the animation off.
- The green state comes from the saved answer, so it's there on every visit.

Two sides
- One row, split by an "Answered" divider: unanswered on the left, answered on the right. Labels above: "To answer · n" and "Answered · n" (tap to jump to the answered side).
- Answering moves the card to the right side straight away and scrolls the row to it while the animation plays.
- Empty states: "Answered questions move here." / "All answered — nice work."

Order
- Each side is shuffled independently once per visit to the Profile page (ProfilePage calls resetQuestionOrder on mount) and stays still while the person is answering. Display order only — answers and completion are never changed.

Wording
- The "Generic" question group is now labelled "Freelancer" everywhere it shows (the internal key stays "generic").


## v16.3 — 2026-10-09 — Profession levels; public profile order + Ask a question
Artifact version 1791501889-f4bd · file `fireflair-v16.3.html`

Two focused additions: a level on each Profession Card, and a new section order for someone else's profile.

Profession level (Profession Card editor)
- New LEVEL field when creating or editing a Profession Card: five boxes, 1 Apprentice, 2 Developing, 3 Professional, 4 Expert, 5 Master. The chosen one is black/gold; tap it again to clear.
- One short line under it: "Profession level helps FireFlair connect Masters with Apprentices for training and development."
- Stored per profession as record.level (1–5, null until chosen); each profession has its own level. Constants: PROFESSION_LEVELS / professionLevelTitle.
- Never shown on the Profile Card, on profession cards, or to visitors (the field only appears in the owner's editor). Purpose: later Master <-> Apprentice training and mentorship matching in FireFlair Core.

Someone else's profile (PersonProfile / ProfileSections when isMe is false)
- Section order: Media, Network, Reviews & References, Professions, then the rest (qualifications, skills, interests, work locations, languages, experience, venues). Empty sections stay hidden, as before.
- Q&A is always the last section. "Ask a question" opens a sheet; the question becomes a Question Card on that person's profile (state.profileQuestions: { id, personId, text, askedAt, by, answer }). In this prototype it shows as "Sent to <name>"; Core needs to deliver it and supply the answer (from the person, or from FF AI using their profile).
- Book · Review · Join moved from under the card to the very bottom, below Q&A (same behaviour, now a shared ProfileActions component).
- Your own profile keeps its existing order.


## v16.2 — 2026-10-08 — Readability: Profile Card and Q&A text
Artifact version 1791498672-eb3d · file `fireflair-v16.2.html`

Readability pass on the Profile Card, Q&A cards and other cards. No layout or colour changes.

Typography rule now used on the profile:
- Tier 1 (names, main profession, questions, answers): biggest, darkest.
- Tier 2 (skills, interests, locations, languages, card titles, descriptions): medium size, strong contrast.
- Tier 3 (labels, card types, XP, status): small but solid, never faint.
- Display type (Cinzel) stays for headings, the card plate and the name. Everything a person writes about themselves is in Inter, which stays legible at small sizes. Cormorant is no longer used for profile content.

Profile Card (editable, in Profile Card step 2)
- Name: larger and bolder (Cinzel, 22px, 700).
- Profession, skill, interest, location and language chips: Inter 13.5px; the first profession (the main one) is bold.
- Typing fields in Inter 15px with stronger placeholders. Row labels are small but darker.
- FF Tag line and footer address in Inter, darker and larger.

Profile Card (finished: Section 5, Network tiles, profile view)
- Main profession bigger and darker gold (#6A4F12 on light cards).
- Row values in Inter semibold, about 1.5x the previous visible size. Labels darker.
- FF Tag address on the black pill is larger, with less letter-spacing.
- The FF watermark behind the card is about half as strong.
- Mini and landscape card formats: profession and address in Inter too.

Q&A cards
- Slightly wider (176–204px). Question in Inter 16px semibold; answer Inter 17px bold. "Tap to answer" is 15px, not tiny italic.
- Group, XP and "Answer" labels are smaller and quieter, so question and answer come first.

Other cards
- Profession / skill / qualification / experience cards, media cards and venue cards: titles in Inter bold 15px, descriptions in Inter 13px with stronger contrast, type labels raised from 6.5px to 8.5px.


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


