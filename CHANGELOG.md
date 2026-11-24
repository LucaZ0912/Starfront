# Spacefarer: Beyond the Veil – Changelog

Versions follow **alpha Phase.Teil.Paket.laufende Nummer** (see Roadmap.md → Arbeitsweise & Übergabe).
Every update gets its own entry, a commit and a git tag `v<version>`.

## alpha 0.8.64.11 – 2026-11-24

**After Luz's second look at package 64: the way with Rook, talks in the bar, a window for the work, music.**
- **The stairs were skipped:** the press that opened the door still counted as the press that skips them. They can
  be skipped only after a moment now.
- **You follow Rook by yourself** on the first way to the bar: across the plaza, through the gate, down the alley,
  up to the counter. No walking of your own until Luz is met. **Rook stops three times on each part of the way,
  turns to you and speaks, standing.** Each line also stands as a line of text on the picture, so that it can be
  read whatever hangs across the street.
- **Night and rain only the first time in Centauria:** from Rook's call until Luz is met, and on until you leave the
  city that first time. After that the city has its own time of day and weather (the party is still at night).
- **After the party everyone of the round can be spoken to,** each with a short talk first:
  - **Ratte:** what is going on (gossip of the Back Alleys, one of nine by lot), or work.
  - **Kraut:** what is going on: the book Kraut reads, on paper, from Earth, about the Peasants' War of 11524 to
    11525 as the Cluster counts the years; asked again, **a fact about that war each time** (fourteen, one after
    the other); or work.
  - **Luz:** **a beer for twelve credits**; what Luz does besides: old Earth bands, obscure punk, and the record
    from Earth Luz once held; asked again, more about the music.
  - **Rook:** how things are, and the Colosseum.
- **A window of its own for the work of Ratte and Kraut:** who offers it (portrait, how well you know each other),
  each job a card with its kind in colour, its system, what it asks and its pay; the job in hand with how it
  stands, to be let go or paid out. Number keys, Esc and a controller work as in every menu on foot.
- **Ratte and Kraut are in the acquaintance window,** from the party on. **Every job done for them makes you
  better friends** (four points); Kraut also for hearing about the book.
- **Music, made on the spot (no files):** in the Static Feedback **three punk songs by night**, when the band plays
  (each twice, then the next), **a quiet tune by day**; **a track for Survivor**. They are made in the background
  the first time they are wanted. The jukebox, once switched on, goes before them.
- **Open:** not played by hand. **I cannot hear the music:** it is checked only for length, level and that it is
  not silent; whether it sounds good is for Luz's ears. The five tracks lie as WAV files in
  `Claude outputs/musik/`. Kraut speaks a good deal more about the book than "says little" allowed until now.
- Smoke tests: `fern64b` (the walk), `round64d` (the talks, the window, the friendship), `music64`, `room64e`.

## alpha 0.8.64.10 – 2026-11-24

**Balance after Luz's first go at the mission ("no chance, even well equipped"): the convoys are far weaker.**
- **Luz's test and the round's information jobs:** the big ship keeps **two guns, none larger than size 2** (it had
  four, up to size 4), each of the two small ones **one gun of size 1** (they had three). **No convoy ship flies
  drones** any more (the Assembly's ships launched theirs).
- **They drop out of warp 4,500 km from you** (it was 2,600): beyond their guns' reach, so the first move is yours.
- **The download takes 45 seconds** (it was 60).
- **Raids** by the size of your ship: a small ship meets a medium one with two guns and one escort with one; a
  medium ship the big one with three guns of size 2 at most; a large ship the big one with five guns up to size 3
  and escorts with two.
- **Open:** these are new guesses, not played. Hulls, shields and speed of the convoy ships are unchanged.
- Smoke test: `luz64c` checks the guns, the distance and the time; `round64d` runs with it.

## alpha 0.8.64.9 – 2026-11-24

**A fix after Luz's report: weapons missing from the fire group settings.**
- **Why they were missing:** a module whose tile of the skill tree is not open is fitted but offline, and the fire
  group settings simply left it out, without a word. That it does not work is as it should be; **the reason is
  shown now,** in a red box at the top of the list: which modules are offline, in which slot, and which tile each
  needs.
- **The skill tree could stay shut for good** (since 0.8.64.1) in a game that was put past the intro another way
  than by the licence scene, the debug menu's story buttons for one: such a game has no licence flag. The tree is
  shut only while the intro really runs now, and the debug buttons of Rook's introduction hand you the licence.
- Smoke test: `tree64a` checks it; `tree`, `firegroups79` and `w59c` run with it.

## alpha 0.8.64.8 – 2026-11-24

**Package 64g (Luz): the round at the bar's games. Package 64 is whole with it.**
- **Once you are of the round,** its people sit at the Static Feedback's games as special opponents, each with a
  word of their own: **Luz** (five stars: very strong) and **Ratte** (three) at the pool table, **Rook** (three) and
  **Kraut** (five: very strong) at the dart board. Beat one and they go into the collection, as Ossa and Dan do.
- **Luz holds the high score** at the bar's cabinet: 12,750, above every regular, until you beat it.
- **Open:** not played by hand. How strong five stars are at the table and the board is what the games made of it
  before; nothing new was tuned.
- Smoke test: the group `games64g`; the groups of the bar games (`minigames54b`, `darts54b`, `w58h`) and `acq60`
  run with it.

## alpha 0.8.64.7 – 2026-11-24

**Package 64f (Luz): Rook and the Colosseum.**
- **The morning after your first night in the room above the bar** Rook is on the radio: come to the Colosseum,
  Line B from Centauria Central. The journal: "Something You Have to See".
- **Rook waits on the plaza before the Colosseum,** at the top of the stairs from the station, a mark over the head
  (and is not in the bar meanwhile). Rook says what the place is: the house's gear, King of the Colosseum, Team
  Deathmatch, Survivor, Coins and the rank that stays (two answers, each with what your pilot says).
- **From then on Rook can be picked as a team mate** in Team Deathmatch. Before that Rook is not in the list (until
  now Rook stood in it from the start). A game without the story is not held back.
- Afterwards Rook is back in the Static Feedback.
- **Debug menu** (Story, "The round"): "Rook's invitation" (Rook waits; on the ground in Centauria it puts you on
  the Colosseum's plaza), "Rook met at the Colosseum".
- **Open:** not played by hand.
- Smoke test: the group `rook64f`; `colteam62a` and `colorder62a` run with it.

## alpha 0.8.64.6 – 2026-11-24

**Package 64e (Luz): the room above the Static Feedback.**
- **A room of your own above the bar,** bare and worn like a student's flat: a mattress on the floor with a crate
  beside it, a worn sofa facing the window, a low table, a heater, a fridge, crates, a locker, a plant, what lies
  about on the floor (bottles, a flat box, a magazine). Old plaster with the brick showing through, a pipe, three
  bills of the band, a string of small lamps.
- **A wide window on the street before the bar,** and the street moves: the fronts opposite with their lit windows
  and blades of neon, a screen that changes, people under umbrellas, the rain on the glass, a craft with a
  searchlight now and then. **Use the window** and the camera goes to the street; use it again or lie down and it
  comes back.
- **Luz shows it to you** right after the party: the picture goes dark, you stand in the room with Luz, a few
  words (two answers, each with what your pilot says), and the room is yours.
- **The door marked PRIVATE in the bar** leads up from then on (it stays shut before). Between the bar and the room
  lies **a stairwell the game walks you through**, up and down, about three seconds; Use or Esc is there at once.
- **The stairs drawn anew** (Luz: they did not look like stairs): a flight seen from its foot, rising away from
  you: every step a lit tread over the dark face of its riser, the steps shorter and narrower towards the top, a
  stringer and a handrail either side, the walls closing in, a doorway with the room's light at its head.
- **The mattress: sleep.** A night passes as in a room of the quarters (new contracts, new faces, the planets
  elsewhere). **The locker:** your gear.
- **The camera stands near** in the room and on the stairs (a small place fills the picture).
- **Debug menu** (Story, "The round"): "The room above the bar" (it is yours and you stand in it).
- **Open:** not played by hand. The mattress still wears the tidy blanket of the quarters' beds.
- Smoke test: the group `room64e`; `round64d` knows that Luz takes you up after the party.

## alpha 0.8.64.5 – 2026-11-24

**Package 64d (Luz): the party, the round, and the round's work.**
- **The party.** After your report Luz pays, the picture goes dark, and the Static Feedback is full: the band plays
  (it is night), guests dance, Rook, Ratte and Kraut stand at the counter with you and say their piece over their
  heads. Luz calls for quiet and **takes you into the round: Luz, Ratte, Kraut, Rook** (one answer of yours, with
  what your pilot says). If the party is cut short, speaking to Luz brings it.
- **Rook stays in the bar** from the day you met Luz, and has a word for you.
- **Ratte and Kraut hand out work**, one job at a time, at their table (a window with what they offer, new every
  twenty minutes; the journal: "Work for the Round"):
  - **Information (Ratte):** as Luz's test: a rendezvous, a count of five, a convoy without markings, a download
    within 8,000 km of the big ship, away. The pay waits at Ratte's table.
  - **A delivery (Ratte):** a sealed crate lies at a drop point in space. Hold still there for three seconds, it
    is aboard; dock with it at the station named. **Paid on docking.**
  - **A raid (Kraut):** the convoy flies its flag. Its biggest ship has to go; a canister tumbles out of the wreck
    and has to be picked up (fly within 800 km). The pay waits at Kraut's table. **Your standing with that power
    suffers**, as for any attack on its ships. The convoy is sized by your ship: a small ship meets a medium one
    with one escort, a medium ship the big one with half its guns, a large ship all of it.
- The systems are the plain neighbours of Fern. Information pays 14,000 to 18,000 cr, a delivery 9,000 to
  12,200 cr, a raid 24,000 to 32,000 cr. Every job done counts as a contract for the skill tree.
- A job can be **let go** at the table of who gave it. A mark stands over whoever owes you pay.
- **Fixed on the way:** the story hooked itself to talks on the ground only once a second, so a word spoken right
  after you came in could go unheard. It listens at once now.
- **Debug menu** (Story): "The party", "Of the round"; a job in hand: "Information", "A raid", "A delivery", "To
  its point", "Done in the field", "Let it go". The debug buttons of Rook's introduction now also work in a game
  whose intro is not over.
- **Not in it** (said outright): a delivery is not scanned by patrols on the way, and the crate takes no room in
  the hold; what a raid drops is no cargo either. The room above the bar, Rook's invitation to the Colosseum and
  the bar games follow with 64e to 64g.
- **Open:** not played by hand; pay and how hard the convoys are are guesses.
- Smoke test: the group `round64d`; `fern64b` and `luz64c` know that Rook stays in the bar.

## alpha 0.8.64.4 – 2026-11-24

**Package 64c (Luz): Luz's test, the first of the new missions: gathering information.**
- **Speak to Luz again** (a mark over the head): Luz hands out the job. An intelligence convoy of the power you
  were NOT registered with (the Covenant if you began with the Assembly, and the other way round) flies through a
  system one jump from Fern. Luz names the system and marks a **rendezvous** there (a waypoint to warp to). The
  journal: "A Small, Ugly Job".
- **On the spot a count of five runs down.** At nothing the convoy drops out of warp beside you: **one big ship and
  two small ones**, without markings, hostile. The big one has left half its guns at home; the small ones are
  patrol ships as they come.
- **You need not beat them.** A box in your hold reads the big ship's computer while you stay **within 8,000 km** of
  it: a minute. Beyond that the download stalls. A display over the module bar shows the count, the download and
  what to do.
- **Then get away:** warp out, or put 30,000 km between you and them. The convoy and the waypoint are gone, Luz
  calls you home.
- **Shot down, docked or out of the system before the download is done:** the meeting is blown. The convoy flies
  that route again whenever you come back to the rendezvous; you need not ask Luz anew.
- **Nobody's standing suffers:** the ships fly without a flag.
- **Back in the bar** Luz hears your report and pays your share (15,000 cr). The party and what follows come with
  64d; until then Luz asks for a day.
- **Debug menu** (Story, "Luz's test"): "Luz has the job", "Job given", "To the rendezvous" (sets your ship on the
  spot in space from wherever it is), "Data taken", "Reported". "Back to before the call" wipes the test as well.
- **Open:** not played by hand; how hard the three are is a guess. If the big ship is destroyed before the download
  is done, the download counts as done at once. The small ships are not weakened.
- Smoke test: the group `luz64c`; `fern64b` knows that Luz hands out the job when spoken to again.

## alpha 0.8.64.3 – 2026-11-24

**Package 64b, after Luz's first look: night and rain, and buttons to test it.**
- **While Rook takes you to Luz it is always night in Centauria, and it rains.** From Rook's call until Luz is met,
  and on until you leave the city, so that the light does not jump while you stand in the bar. The band plays, as
  on every night. The debug menu's own weather still goes before it.
- **Debug menu** (Story, "Rook's introduction"): "Land in Centauria" (works from anywhere: it makes Rook's call,
  flies to Fern and lands), "Top of the stairs" (Rook waits), "The alley" (Rook ahead of you), "The bar, before
  Luz", "Luz met". The last four need you on the ground in Centauria. In a game without the story they start the
  open game as it is after the intro.
- **Luz looks different** (Luz): slim, a sidecut, a scar across the right eye, eyeliner; the neon pink lips stay.
- Smoke test: the group `fern64b` lands through the new button and checks the night, the rain and every point.

## alpha 0.8.64.2 – 2026-11-24

**Package 64b (Luz): Rook takes you to Luz.**
- **Fern is closed** until somebody there vouches for you: the gate refuses the jump ("you hold no entry permit").
  **Rook's call at pilot level 5** brings the permit, and Rook asks you to come to Centauria. A game without the
  story is not held back.
- **After the landing in Centauria Rook is on the radio:** take Line A from Centauria Central, get off at the
  Commercial District.
- **Rook waits at the top of the stairs** from the station, a mark over the head, and greets you as you come up
  (two answers, each with what your pilot says).
- **Rook goes ahead:** across the plaza to the gate of the Back Alleys, down the alley to the door of the Static
  Feedback, and says on the way what this place is (lines over Rook's head, and in the log). **Rook waits when you
  fall behind** and looks round for you. On every new part of the way Rook is ahead of you again.
- **At the counter Rook introduces you to Luz.** Luz owns the bar and brings people together; that is the trade.
  Luz wants to see you fly before handing you on, and has a job for that (the job itself comes with 64c; until
  then Luz says it is still being set up).
- The journal's task "A Place Called Fern" has two goals at its last step now: meet Rook, follow to Luz.
- **Debug menu** (Story): "Fern: Rook's call now", "Back to before the call".
- **Open:** not played by hand. Rook's lines on the way are short; on the plaza the gate is near, so only one or two
  of the three are said before Rook stands at it.
- Smoke test: the group `fern64b`; `fern61` knows that Rook is part of it now.

## alpha 0.8.64.1 – 2026-11-24

**Package 64a (Luz): the skill tree in the intro.**
- **The fault:** with the pilot licence the skill tree went back to its trunk, but everything could be opened again
  at once, because what you had done in the intro still counted.
- **Through the whole intro, up to the pilot licence, the skill tree is shut.** No tile gets ready, none can be
  opened. Its page in the Pilot window says "No pilot licence" and why. What the story itself opens for you (Dan's
  mining, the Maul) stays as it was.
- **Nothing of the intro counts.** With the licence every counter the tree reads (warps, jumps, ore, kills,
  contracts and the rest) starts at nothing and counts from there. Your pilot level stays.
- **A new line in the scene of the licence,** said by the official after the stamp: "One thing more. From now on you
  earn your licences yourself: through what you do and what you achieve. You will find them in your skill tree."
- A game without the story is not held back.
- Smoke test: the group `tree64a`; `tree` and `w59c` run with it.

## alpha 0.8.63.1 – 2026-11-24

**Package 63 (Luz): new ships. Four of them.**
- **Earthworks 190SL**, the pilot's old ship of the intro, no longer built. It keeps its shape (white hull, swept
  wings with two drive pods, a glass canopy, gold stripes) and has been brought up to date: chrome along the hull,
  the bow, the wings' leading edges, the pods and the stern. A small ship that is faster than what was built before
  this package, with a hull far stronger than its size (structure 1,500), fair weapons (three places), next to no
  shield (a third of what its modules give) and no drones. **A gate jump costs it a fifth of the fuel.**
- **It is sold at no yard.** It is the house's prize at the cashier of the Grand Centauria: **1,000,000 Coins**. The
  cashier's window has a new line, "The house's prize". It comes with its standard fit and stands in Centauria's
  hangar afterwards.
- **Mistral**, Maison Aurelle's racer (small): a long bow in your colour that fades in dots into ivory; aft the hull
  splits into two blades and a spine with the machinery open between them, a drive at the end of each. With its
  standard fit it flies 955 km/s, the fastest ship before it 417. Strong shields for its size, next to no hull
  (structure 120), two weapon places, no drone hangar. **Three thrust bursts** instead of one.
- **Soleil** (medium) and **Sovereign** (large), Maison Aurelle's private yachts in obsidian black with **gold lines
  along which a light runs** from the stern to the bow, and a lot of glass. The Soleil is a flying wing with four
  drive nacelles, a glass canopy and a glass back. The Sovereign is a long blade; a ring round her stern, held by two
  spokes, carries her drives; a glass back with a pool, a lounge under glass inside the ring, a row of lights down
  her bow. Both are the fastest ships of their sizes, well fitted, with **two thrust bursts** and a built-in
  afterburner; the Sovereign is fast in warp as well.
- **Thrust bursts by the hull.** A hull may hold more than one. They come back one at a time, 15 seconds each. The
  HUD shows how many are left on a hull that holds several.
- **A flame behind every drive** on these four, where a ship had one flame on its centre line before.
- The three Aurelle ships are sold where Maison Aurelle sells (trade stations of rich systems, by the station's
  tier): Mistral 380,000 cr, Soleil 900,000 cr, Sovereign 3,500,000 cr.
- **Debug menu:** "+1,000,000 Coins" beside the casino's buttons. The four hulls are in the list "New ship".
- **Not in this package:** the "special casino ships" and the news item about the 190SL as a collector's piece, both
  from the old line of the Roadmap. The yachts do nothing as a sign of rank beyond what they are.
- **Open:** nothing flown by hand yet. All figures are first guesses. The Mistral with a larger engine than its
  standard one flies about 1,570 km/s; whether autopilot and docking stay clean at that speed is not checked.
- Smoke test: the group `ships63`; the groups `drones` and `casino62` know the new ships and the cashier's new line.

## alpha 0.8.62.31 – 2026-11-24

**Package 62a, part 11c (Luz): the bosses of the Alien Laboratory. The stage is whole now.**
- **No walls of light on this stage.** When a boss is here, the doors of a hall shut instead: fields of force across
  its doorways, for you and for them, until the boss is out. Nobody new comes while they are shut.
- **The Apex** (at 7:30), the hunter the laboratory bred: black and glossy, a low body of ribs with a green light
  inside them, four legs, two arms that end in sickles, a crown of spines swept back from its head, a tail of
  vertebrae with a blade at its end. A creature of its own, in the manner of the biomechanical.
  - It is faster than you. If you stand in a corridor when it comes, it hunts you down the corridors; the doors
    shut once you enter a hall, and it comes in after you.
  - It takes aim along a line you can see, and leaps along it until a wall or what stands in the hall stops it.
    Then it stands open for a moment.
  - From two thirds of its health: three leaps in a row, from wall to wall, and then a ring of force out of its
    tail.
  - In its last third the light goes red. It is faster still, and every other time it spits a fan instead that
    leaves pools where it lands.
  - Put out, it leaves a great weapon crate, and the doors open.
- **The Mastermind** (when the fifteen minutes are up): what slept in the great tank of the Core Hall. The glass
  bursts and it rises: a brain as large as a rover, one great eye in its front.
  - Until you stand in the Core Hall nothing reaches it, and it does nothing. A sign at the edge of the picture
    shows the way; the gold guide lines lead there too. Once you are in, the doors shut.
  - Rings of thought with two gaps in them, faster with each third it loses. They pass what stands in the hall;
    only a wall ends them. Little green men come to it.
  - From two thirds: it hurls what stands in its hall, consoles and tanks, onto marks, the first of them where
    you stand. The hall is the emptier for it. With nothing left to hurl, pieces of its tank.
  - In its last third: it pulls you to it, a round about it wears you down, and Greys come in through the walls.
  - Put out, the stage is held.
- Both leave cores as the other bosses do (twelve and thirty), and both stand in the collection (thirty-five kinds
  in all).
- Not played by hand. How hard the two are is a guess.

## alpha 0.8.62.30 – 2026-11-24

**Package 62a, part 11b (Luz): the rest of the Alien Laboratory: three more kinds, three things by the clock, an item of its own, laser grids.**
- **Three more kinds.**
  - **Trooper** (from 4:30): a green one in a suit and a glass helmet, with a ray gun. It keeps its distance, takes
    aim along a line you can see and fires a slow ring of light. A wall turns the ring back, once.
  - **Brain** (from 6:00): a brain under a dome of glass, hovering. While it is in the hall with you it pulls you
    towards it: you walk away from it slower, and standing still you drift to it. Leave the hall, or put it out.
  - **Saucer** (from 2:30, every 45 seconds): two of them abreast, later three, along a line shown first, a tractor
    beam under each. Who stands in a beam is hurt and held for a moment. A dodge frees you, and takes you through.
  - A trooper or a brain that is not in the hall you stand in comes through the doorways first, as the others do.
- **Three things by the clock.**
  - **Lockdown:** for fifteen seconds fields of force close the doorways of the hall (or corridor) you stand in.
    Nobody passes them, you neither. A Grey walks in through the wall as ever.
  - **Purge:** a warning over the hall you stand in, a count under your feet, and after four seconds it burns. It
    costs you a great deal if you stay, and it burns them just the same: lead them in, and leave. Out in the
    corridor nothing happens to anybody.
  - **Containment Breach:** in the hall nearest to you that still has whole tanks, the four nearest to you burst,
    and a specimen comes out of each. The banner names the hall.
- **Laser grids** across six of the doorways (never one of the Core Hall's): on for a little over two seconds, off
  for a little under three, flickering before they come on. They cost you and them alike, and throw you back.
- **Containment Seal**, an item that lies in this stage's crates only: for ten seconds fields of force close every
  doorway of the hall you stand in. Nobody comes in, and what touches a field burns. You may leave. A Grey still
  walks in through the wall.
- A field of force holds a crowd too: nobody is pushed through it, pulled through it by a gravity well or a black
  hole, or thrown through it.
- The collection's Survivor has the three new kinds (thirty-three in all).
- Not built yet: The Apex and The Mastermind (part 11c). Until then the stage has no boss.
- Not played by hand. All figures are first guesses.

## alpha 0.8.62.29 – 2026-11-24

**Package 62a, part 11a (Luz): Survivor's fourth stage, the Alien Laboratory: its ground, its walls, its first three kinds.**
- **A stage with walls.** The first three stages are open fields. The Alien Laboratory is nine halls in a grid of
  three by three, each joined to its neighbours by a wide corridor; the doorways are as wide as the corridors, and
  no hall is a dead end. You begin in the middle one, the Core Hall, beside a great sealed tank.
  - Specimen Hall (two): rows of tanks, something in each. A few are broken, and their nutrient on the floor holds
    back whoever walks through it.
  - Operating Theatre (two): tables under their lamps, instrument carts.
  - Hangar: a parked saucer, landing rings.
  - Cryo Vault: pods along the wall and in rows, frost.
  - Holding Pens: cells behind fields of force.
  - Trophy Room: what they took, held in stasis: tractors, cows, road signs.
  - Core Hall: the great tank, cables from it to four rows of consoles.
  - Every hall has its letters on the floor (A1 to C3), and two guide lines run down each corridor, in the colours
    of the two halls it joins.
- **They find their way.** On a stage with walls they do not walk straight at you: they take the shortest way
  through the doorways, spread over a doorway's whole width. Where two ways are as short, half of them take the
  one and half the other, so they come at you from both sides.
- **What you fire meets the walls** (Luz: it bounces off them).
  - Turned back by a wall: the drone's shots (three times at most), the Silverblades, a black hole, the
    Superlaser's beam (once).
  - A grenade thrown at a wall comes down this side of it; so does a gravity well.
  - What looks for a target needs a free line to it: the Laser and its jumps, the Sentry, the Taser's chain.
  - What works on a field needs a free line from its middle: the Pulse, the cold, the Taser, a grenade's burst, a
    mine, the Fusion Halo's ring.
  - The Plasma Orbs are drawn in where a wall stands in their round.
  - The other three stages have no walls and play as before.
- **Three kinds.**
  - **Little Green Man**, the swarm: half your height, a head far too large, two antennae.
  - **Grey** (from 1:30): it walks straight at you through the walls. Inside a wall it is pale, nothing reaches it,
    and it cannot touch you.
  - **Specimen** (from 3:00): something out of a tank. Slow, and it takes a great deal.
- The stage opens once The Ice Worm is put out on Whiteout. Its picture before a run: a hall of tanks.
- The collection's Survivor has the three new kinds (thirty in all).
- Debug menu: the stage Alien Laboratory.
- Not built yet: the Trooper, the Brain, the Saucers, the three events, the Containment Seal and the laser grids
  (part 11b); The Apex and The Mastermind (part 11c). Until then the stage has no boss: who holds out fifteen
  minutes has held it.
- Not played by hand. All figures are first guesses.

## alpha 0.8.62.28 – 2026-11-24

**Package 62a, parts 10b and 10c (Luz): a suit for Survivor, and its version for outside the arena.**
- **The Survivor rig.** In Survivor you now wear a rig of your own. It shows how far you have come at the Survivor
  console, in ten steps, and changes nothing else:
  - at first an undershirt, trousers and bare arms;
  - then, with every tenth bought at the console, one more piece: armoured boots and a belt with the first light;
    bracers; greaves and knee caps; a cuirass with its core; pauldrons edged in gold; a black undersuit, thigh
    plates and gloves; seams of light; a cape with a gold hem; a gorget and a laurel of light;
  - at the last the whole regalia: high pauldrons, bands of light running down the cape, a ring of light behind
    the head, the edges gold.
- Its lights are alive: the core, the belt and the bracers beat slowly; the seams, the cape's bands and the ring are
  lit one after another, so the light runs. At the last step the light wanders through the colours (gold, green,
  blue, violet, pink; no red, red belongs to the others) and sparks rise round you.
- You see it in the run, in the picture before the run, and in Survivor's room, which shows your step and when the
  next piece comes. The console names the step too.
- **The Champion's Regalia.** With the last thing bought at the console the Colosseum gives you the rig's last step
  as a suit for outside the arena (into your pockets, else your ship's locker, else it is kept until you have room).
  It is never sold.
  - Two drone places, both drones carried on the shoulders, as on the Senate's armours. The drones themselves are
    not part of it.
  - Built in, in its first weapon place: the **Silverblade Drone**. With it in hand and your target in reach it
    is thrown: it cuts the target, darts on to the next of those who fight you, bounces off walls and at the end
    of its reach, and comes back after about three seconds. Then it takes nine seconds until it is ready again,
    whatever is in hand meanwhile. At rest it hovers by your shoulder.
  - A closed helmet where one is needed. Shield and plate between the light and the heavy combat suit, and
    not slowed as the heavy one is.
- Debug menu: the rig's step up and down, back to what is bought; buy everything (which gives the Regalia).
- Not played by hand yet. The Regalia's figures and the blade's are first guesses.

## alpha 0.8.62.27 – 2026-11-24

**Package 62a, part 10a (Luz): the collection's Survivor.**
- A new category in the pilot's window under Collection: **Survivor**, with all twenty-seven kinds, by stage
  (Outbreak, AI Takeover, Whiteout).
- A kind is open once you have put one of it out. Until then: its silhouette and "???".
- Open, a tile shows its picture, whether it is a boss, how many of it you have put out so far, and a few words
  about it.
- A run counts what it puts out kind by kind. At its end the count goes into your record, and the kinds met for
  the first time are named in the log. (A run you quit the game in is not counted, like its cores.)
- Debug menu: ten more of every kind.

## alpha 0.8.62.26 – 2026-11-24

**Package 62a, part 9c (Luz): the bosses of Whiteout. The stage is whole now.**
- **The Ice Worm** (at 7:30, in the walls of light):
  - Under the ice nothing reaches it, and none of your weapons takes aim at it. It circles you there, its long shape
    showing through the ice. The display says so.
  - Then red marks show where it will break out, the first where you are going: one mark at first; three from two
    thirds of its health down; five from one third down. It breaks out at each in turn: who stands there is hurt
    and thrown, and from two thirds down needles of ice fly out all round.
  - After the last mark it stays above for about three seconds and can be hurt (from two thirds down it throws a
    fan of needles at you meanwhile); then it dives again.
  - Put out, it leaves a weapon crate (three rewards at least), pays 12 cores, and the run goes on.
- **The Storm Heart** (when the time is up; the clock stands while it lives):
  - A crystal in the eye of a storm. It does not move. Inside the eye you are safe from the storm; out there you
    lose health twice a second, whatever shields you. A red line shows the eye's edge, the display says when you
    are out.
  - The eye is wide at first and closes as the Heart is worn down, to well under half.
  - Rings of needles with a gap to slip through; from two thirds down bolts of lightning onto marks where you are
    going; from one third down two arms of needles turning round it, and Gliders. Mites come in at the eye's edge
    all the while.
  - Put out, the stage is held: 30 cores on top.
- What a Glider lets fall bursts as ice now, and lightning strikes as lightning (both used to burst like one of
  your own grenades).
- Debug menu: Worm, Heart.
- Not played by hand yet: how hard the two are is a first guess.

## alpha 0.8.62.25 – 2026-11-24

**Package 62a, part 9b (Luz): the rest of Whiteout: two more kinds, three things by the clock, an item of its own.**
- **Shardthrower** (from 4:30): it keeps its distance, raises its arm (red lines show where), then throws three
  needles of ice in a fan; an alpha throws five. Step aside and they pass.
- **Gliders** (from 2:30, every 45 seconds): a word and red lines first, then two of them (three from 8:00 on) sail
  along those lines and let chunks of ice fall, each onto a red mark. The ice hurts; the gliders themselves do not
  touch you.
- **Blizzard** (3:30, 8:30, 12:00): for eighteen seconds you see only a round about you; all else is white, snow
  driving across. Your weapons work as ever.
- **The ice breaks** (5:00, 9:30, 13:20): up to seven plates crack, the one you stand on among them (red, the cracks
  growing), then break. It costs you who stands on one, and them too. The open water stays a moment (to see only).
- **Avalanche** (6:40, 10:50, 14:10): a red line at one edge and arrows across the field, then a wall of snow
  crosses it. In the open it hurts you and throws you along; it carries them off and hurts them. Behind something
  solid (a boulder, a container, a block of ice) you are safe: the display says "IN COVER".
- **Thermal Charge,** an item in Whiteout's crates only: the ice round you melts. A Rimeback's shell is gone at
  once, a Burrower under the ice comes out stunned, a frozen crate thaws; and the heat hurts them.
- The stage's room shows it: who comes, the Gliders, nine things by the clock.
- Debug menu: Shardthrower, Blizzard, Icebreak, Avalanche, Thermal.
- Still to come (part 9c): The Ice Worm and The Storm Heart. Until then the stage has no bosses.
- Not played by hand yet.

## alpha 0.8.62.24 – 2026-11-24

**Fixes, comfort and balance after Luz's play (24 Nov 2026).**

Fixed:
- **A load down on a planet** put you onto the planet's map every time. A save now keeps where you stand on foot (the
  place, its level, the spot), and a load puts you back onto it: in a city, a settlement or at a landing field.
  Not kept: a fight, a run of Survivor (you stand in the Colosseum's lobby), a ride on a train (its station), a site
  to explore, your room, the clinic (you stand where the city or the field begins). Older saves, which do not say
  where you stood, still open the planet's map.
- **Survivor: late in a run nobody seemed to drop a shard.** With five hundred shards on the field a new one was
  added to one of them by lot, anywhere on the stage. Now the shard furthest from you comes to where the one went
  out, with what it was worth: a shard always falls where it should, and nothing is lost.
- **Survivor: no fusion came.** A fusion comes as a card of a new level, so with no shards there were no levels and
  no fusions: the fix above brings them back. On top of that a weapon crate now gives a fusion that is ready (the
  weapon at level 5, its bonus carried) before anything else.

Comfort:
- **Survivor's room with the controller:** the cross on a stage takes it and goes on to the weapons; on a weapon it
  takes it and goes on to READY. Where something cannot be taken (a stage still shut, a weapon still locked) you
  stay.
- **What is theirs is red on the ground, and only that.** Every attack of theirs that hurts on the ground has a
  clear red round, whatever colour the thing itself has: acid, a bloater's cloud, a stamp, a shell's mark, a boss's
  ring of force, a searchlight's edge. Nothing of yours draws red or orange on the ground any more: the black
  hole's ring, the Minefield's light, the Sunlance's burn and the Atomic Bomb's ring are gold now, and the colours
  the ultimates run through leave red out (gold, green, blue, violet, pink and back).

Balance:
- **Pulse:** weaker (damage 4 / 6 / 8 / 10 / 13 in place of 6 / 8 / 10 / 13 / 16), and it throws them back well
  over twice as far as other hits. The Nova Field, which burns without a pause, throws only a little each time.
- **The bonus for throwing back** is there already: the Mass Driver (a quarter further with each level). It no
  longer works on what pulls them in, the Gravity Well and the Blackhole Gun: their hits do not throw at all.
- **Superlaser:** it comes more rarely (every 18 … 12 s in place of 14 … 8) and reaches further (210 … 370 in place
  of 150 … 300).
- **Drone:** a shot strikes a little further round itself.
- **Silverblade Drone:** a new blade darts at the nearest of them, a second at the next nearest, and so on; by lot
  only when nobody is near.
- Not played by hand yet.

## alpha 0.8.62.23 – 2026-11-24

**Package 62a, part 10 (Luz): Survivor and the fights have rooms of their own.**
- **Behind the fighters' gate you choose first:** two large tiles, MATCH MODE on the left, SURVIVOR MODE on the
  right. Each shows where you stand (the rounds of the two fights; your stage, best time, runs and cores).
- **Match mode** leads to the fighters' room as it was, now with the two fights only (King of the Colosseum, Team
  Deathmatch).
- **Survivor mode** leads to a room of its own. All that the fighters' room showed of it is there, with room to spare:
  - the stages as large tiles, and under them what the one marked is made of: its dangers, who comes from when
    (with their pictures), its bosses and when they come, the flood, what opens it;
  - the weapons you can begin with as large tiles, their full names, and under them what the one marked does: its
    words, its figures at level 1, what its levels bring, what it fuses into and what that does.
- Back out of a room leads to the choice again; back out of the choice leads to the lobby. After a fight or a run
  "next" leads straight into the room of the mode you played.
- **READY with the controller:** it is a place to stand on now in both rooms (down from the last mode, or down out
  of the weapons; a frame shows it), and the cross presses it. The triangle still does, and so do the square and
  Options.
- Not played by hand yet.

## alpha 0.8.62.22 – 2026-11-24

**Package 62a, part 7f (Luz): Survivor: the crates in two kinds, a draw for the weapon crates, what the items look like.**
- **Item crates:** the crates lying on a stage and the supply drops always hold an item now, never a level.
- **An item's sign springs up over you** when you take it, stands a moment, then goes down to where what lasts is
  shown. Its name runs across the picture as before.
- **Weapon crates:** what an alpha leaves and what a boss leaves. Golden, a beam of gold over them, rays turning;
  the arrow to one at the edge of the picture is golden too.
- **The draw:** taking a weapon crate opens a window, and the run stands still behind it. Reels turn and stop one
  after the other, each on a level of something you carry (the same thing can come twice). When nothing you carry
  can rise further, a reel gives a med cell or a purse.
- **One, three or five:** an alpha's crate holds one reward (80 %), three (16 %) or five (4 %). A boss's holds
  three at least, and five one time in four. Three is a TRIPLE DRAW; five is a JACKPOT, with rays of every colour
  and lights raining down.
- E, Enter, Space, a click or the pad's cross stops the reels still turning; pressed again it closes the window.
  What the reels show is yours from the moment you take the crate.
- **Lucky Find** raises those chances now: 3 % more for three and 1 % more for five with each level. It no longer
  makes a crate hold a level; supply drops still come sooner.
- **What the items look like:**
  - Atomic Bomb: a white flash, a ball of fire, a ring of force over the ground, then its cloud: a stem, a cap
    rolling out, a collar round the stem. It cools from fire to smoke and drifts away. The earth stays scorched for
    a while.
  - Shield: a dome of six-sided cells, a wave of light running over them. It flashes when one of them is at it and
    flickers before it goes.
  - Magnet: lines of its field winding in to you, and every shard draws a long trail of light.
  - Medkit: crosses of green light rising round you, a ring running out over the ground.
  - Stasis: a wave over the field as it begins, and a clock round you that shows what is left of it.
  - Overdrive: gold light round you, rings turning, sparks rising, echoes of you where you just were.
  - Override: a small green sign over every machine it turned.
- Debug menu: "Draw 1", "Draw 3", "Draw 5".
- Decided by me, since Luz's answers to the Steckbrief's questions are still to come: weapon crates come from alphas
  and bosses only; they give levels of what you carry and nothing new; the chances above; a key stops the draw.
- Not played by hand yet.

## alpha 0.8.62.21 – 2026-11-24

**Package 62a, part 9a (Luz): Survivor's third stage, Whiteout: a moon of ice by day.**
- **Whiteout** opens once you have put out The Warden on AI Takeover (the boss at 7:30 of the stage before, as AI
  Takeover opens with The Foreman). The first stage by day: snow and ice in place of the dark, and those who come
  are dark shapes on it.
- **Its ground:** snow all over, two tracks trodden into it that cross in the middle; boulders, blocks of ice,
  clusters of crystals, and what a research station left behind, snowed in (containers, snow crawlers, a lookout,
  a dish; its two domes and its mast north-east of the middle). Drifts of snow, hairline cracks.
- **Bare ice:** ten floes of it. On one you keep your way and turn it only slowly; let go and you slide on. A
  dodge goes where it goes. Those who come do not slide.
- **Steam vents:** twenty-six holes in the ice, each steaming while it is ready. Step on one and it bursts: its
  steam scalds all of them within its round (not you), reaches Burrowers under the ice there, and melts a
  Rimeback's shell at once. Then the vent rests for sixteen seconds; a ring round it shows how far that has run.
- **Frozen crates:** the sixteen crates of this stage are frozen in, each beside a vent. Only that vent's steam
  thaws one. Supply drops and what an alpha leaves are free as ever.
- **Frost Mite:** the swarm. Small and weak, and faster than the swarms of the other stages.
- **Burrower** (from 1:30): it runs under the ice three times as fast as it walks, to where you will be in a
  moment. Nothing reaches it there: no hit, no cold, no shock, and nothing of yours takes aim at it. You see a dark
  shape and the ice cracking over it. Where it stops, a red round shows for a moment; then it breaks out and
  hurts who stands in it. It stays above for five seconds and can be put out then; then it dives again.
- **Rimeback** (from 3:00): slow and tough, a shell of ice on its back that takes the hits first. Its picture
  shows whether the shell still stands.
- **The picture before a run** and **the fighters' room** know the stage: a picture of its own, a colour of its
  own (each stage's colour comes from the rules now); a stage that is still shut names the boss it asks for.
- **By day** light alone does not show on the ground: shards have a shade behind them; a crate's beacon and the
  Pulse's ring have a body to them. The other effects of your weapons are paler here than by night.
- **Snow on objects:** any object of the ground can carry a cap of snow now (`"snow": true`).
- Not built yet (parts 9b and 9c): the Shardthrower, the Glider, what happens by the clock (blizzard, breaking
  ice, avalanche), the Thermal Charge, The Ice Worm and The Storm Heart. Until then the stage has no bosses: hold
  out fifteen minutes and it is held.
- Debug menu: the three kinds, "Vent" (the nearest one bursts), the stage Whiteout.
- Not played by hand yet: every figure (paces, how the ice holds you, what the steam does) is a first guess.

## alpha 0.8.62.20 – 2026-11-23

**Package 62a, part 7e (Luz): Survivor: the Silverblade and the Taser reworked, a thirteenth weapon, every ultimate in wild colours.**
- **Silverblade Drone:** its trail is thinner and far longer. As before it cuts nobody: only the blade does.
- **Silver Storm** (its ultimate) no longer circles you: one more blade (four), and they stay for good, darting
  and bouncing as ever. Their trails are longer still, beat in every colour of the rainbow, and cut what they
  touch.
- **Taser:** a cone of lightning the way you look, in place of the small round field. Longer with every level.
- **Plasma Orbs,** a new weapon (30 cores at the console): orbs of plasma circle you for a while and burn what
  they touch, then they are gone until their interval is over. One orb at first; with its levels more of them
  (up to four), a wider round, a longer stay. The Stabiliser makes them stay longer, as it does for blades.
- **Gyroscope,** its bonus (18 cores): what circles or darts for you is faster. Orbs turn faster, blades fly
  faster, the drone's gun turns faster and so fires its round sooner.
- **Fusion Halo,** its ultimate: the orbs stay for good, a second ring of them turns the other way further
  out, lightning runs from orb to orb, and every five seconds a ring of plasma bursts out from them and hurts
  whoever it passes.
- **Every ultimate beats in wild colours now** (Luz: an overload of the senses). The Nova Field runs through
  the whole rainbow, with two lattices turning against each other. Prism beams, Chain Lightning, the Carrier
  Swarm's shots, the Minefield's links, the Battery's field, the Singularity's arms and the Event Horizon's
  discs change their colours as they go; every comet of the Plasma Rain has a colour of its own, and so has
  its burst; the Sunlance throws filaments and sparks of every colour and cools through them behind its beam;
  Absolute Zero keeps to the colours of ice, with bands of northern light.
- The console and the fighters' room show seven weapons to a row, since there are thirteen.
- Fixed on the way: an icon that turned its own drawing aside and with it all the console drew after it.
- Not played by hand yet.

## alpha 0.8.62.19 – 2026-11-23

**Package 62a, part 7d (Luz): Survivor: what you see of your weapons, and the flood.**
- **Numbers of damage:** what a hit took floats up over whoever it hit, in the colour of the weapon that dealt
  it (the pulse cyan, the laser red, plasma green, the drone amber, the superlaser pink, the silverblade
  silver, mines orange, the sentry pale cyan, the cryo ice blue, the gravity well violet, the taser yellow,
  the black hole orange; anything else white). What one of them takes within a moment is added up into one
  number; its last blow shows at once. Larger hits are written larger; a hit that struck twice as hard (the
  Capacitor) carries a "!"; what a shield took is blue. Never more than ninety at once.
- **The Silverblade Drone** draws a trail of silver behind it.
- **The Drone** is there to see now: a small drone that flies at your shoulder. Every interval it turns its
  gun once round and fires its shots one after another, all ways in turn, no longer all at once. Under an EMP
  it holds its fire. **Carrier Swarm:** three drones circle you, each firing its own round (eleven shots each),
  all going through whoever they hit.
- **The ultimates look the part now:**
  - **Nova Field:** a field of light with ripples running out in it, a lattice turning, a rim of dashes with
    lights along it; it beats each time it burns.
  - **Prism Array:** split light: the beam from you, then cyan, then violet where it jumps on, fringes of
    colour beside it, a star where it strikes; the beams stand a moment longer.
  - **Plasma Rain:** comets out of the sky onto marks that close in; where one lands: a flash, two rings,
    sparks, embers.
  - **Sunlance:** a beam like a sun's, gold and white, filaments flickering along it, a sun at its root, what
    it leaves behind fading after it, a burnt arc on the ground where it ends.
  - **Silver Storm:** larger blades, each drawing its trail along the round; the round itself marked on the
    ground.
  - **Minefield:** light runs from mine to mine of a ring, each mine stands in a light of its own; a burst is
    a ball of fire.
  - **Battery:** the three guns stand in a triangle round you now, a field of light between them, light
    running from gun to gun and to you; heavier shots with a star where they strike.
  - **Absolute Zero:** a front of ice with spikes on it, crystals in what it has crossed; cracks in the frost
    stay on the ground for a while.
  - **Singularity:** arms of light winding into a dark heart, motes falling in; at its end all falls to a
    point, then a ring of force runs out.
  - **Chain Lightning:** bolts that fork, two over one another, a star where each strikes.
  - **Event Horizon:** a wider disc of light in three layers, streaks falling in, a wake on the ground behind
    each hole.
- **The flood** (Luz): from 13:00 to the end the swarm comes in absurd numbers: ninety more a second on top of
  the usual, up to a thousand at once (six hundred until then), each with only 40 % of the health its kind
  would have by then. On Outbreak it is announced as "THE FLOOD", on AI Takeover as "ALL UNITS". Not while a
  boss's walls stand.
- Debug menu: let the flood begin.
- Measured: a step with a thousand of them costs about 1.6 ms; sixty pictures a second with a thousand on the
  screen and five weapons firing.
- Not played by hand yet.

## alpha 0.8.62.18 – 2026-11-23

**Package 62a, part 8c (Luz): the bosses of AI Takeover: The Warden and The Core.**
- **The Warden** comes at 7:30, inside walls of light as on Outbreak (nobody new comes meanwhile, those already
  there stay). A walker on four legs: a broad armoured hull, a turret with one red eye, a rocket pod on each
  shoulder, the lens of its laser on a mast.
  - **Its laser arm** turns round it all the while (it warms up first; a thin ring shows how far it reaches).
    To touch it hurts and throws you outwards. Dodge through it, or walk with it close by. In its last third
    a second arm turns opposite the first, and both turn faster.
  - **Rockets:** again and again a salvo onto marks, one where you stand, the others round you (five of them,
    later seven and nine).
  - **Its stamp:** come near and it rears up, standing (a ring shows how far it will reach), then a ring of
    force runs out from it.
  - Put out, it leaves a great crate, and the walls fall.
- **The Core** comes when the fifteen minutes are up; the clock stands while it lives. The mind of the
  machines: a sphere of dark steel held in two claws over a pedestal, an eye of red light in it. It stands in
  the middle of its field, four pylons round it.
  - **Behind its shield:** while one pylon stands, nothing reaches The Core (a dome over it, fed by the
    pylons; its bar is blue and says how many pylons stand). The pylons fire in turn: a line that follows you
    and then holds still for a moment, then the beam along it. The fewer stand, the faster they fire. A pylon
    that is hurt shows a bar.
  - **The cross:** with the last pylon the shield falls. Four arms of light turn round The Core, out to the
    walls: walk with them near it, or dodge through one. It calls machines: Enforcers, later Scouts.
  - **The floor:** from 45 % of its health down, squares of the floor light up (yours always among them,
    never two side by side), brighter and brighter, then they burst. The cross turns on meanwhile, a little
    slower.
  - Put out, the run is won.
- Cores: 12 for The Warden, 30 for The Core, as on Outbreak.
- Debug menu: let The Warden and The Core come.
- Not played by hand yet: all figures are first guesses.

## alpha 0.8.62.17 – 2026-11-23

**Package 62a, part 8b (Luz): the rest of AI Takeover: four more kinds, what happens by the clock, Override. And a crash fixed.**
- **Fixed: a crash in Survivor** (Luz, 23 Nov 2026: "Out of bounds get index '28094' (on base:
  'PackedByteArray')"). Those that fly (the Hunters here, the screechers of the flock on Outbreak) come from
  beyond the edge of the ground and leave across it. In two places the game looked up the ground under them
  all the same: where fire burns, and in the rows that find neighbours. When you stood near the edge of the
  ground as they came, that broke the run. Both look only where there is ground now.
- **Bulwark** (from 4:30): the Precursors' robot as the machines run it now, a tall shield before it, heavy
  plates on its shoulders, a mortar's tube over its back. Slow and tough (a bar over it once it is hurt). Now
  and then it stops, marks where you stand, and lobs a shell onto the mark: step off it.
- **Seeker** (from 6:00): a mine that rolls, fast, in twos and threes. Near you it arms itself (it blinks, a
  ring shows how far its burst will reach), then it goes off. Its burst hurts the machines round it more than
  you. One you put out goes off as well, and sets off the next beside it.
- **Jammer** (from 8:30): a mast on three legs that keeps well back. The machines in its field (a ring shows
  it) carry a shield that comes back again and again while it stands: put it out first.
- **Hunters** in place of a flock (from 2:30, every 45 seconds): a red line shows where one will fly, then it
  comes along it, a beam burning down from it. From 8:00 two abreast. Step off the line.
- **By the clock:**
  - **Searchlights** (2:00, 5:00, 8:00, 12:00, 14:00): two of them hunt you for 25 seconds, slower than you
    walk. Stand in one for a second and a half (a ring round you fills, a plate says "IN THE LIGHT: MOVE") and
    you are marked: a second later a shell comes down out of the sky where you stood. It hurts machines too.
  - **Reinforcements** (4:00, 12:30): landing pods come down on marks in a ring round you; three of the swarm
    step out of each.
  - **The kill line** (6:30, 10:00): a line of light warms up at one edge, then crosses the whole field. Walk
    through one of its two gaps, or dodge through it.
  - **The EMP** (11:00): for five seconds none of your weapons charges; a plate lies over them meanwhile.
- **Override,** a new thing, in this stage's crates only: the machines near you are yours for eight seconds
  (lit green): they leave you be and strike the others, then they turn back. Not bosses, not those that fly.
- An alpha of this stage is announced as "A PRIME".
- Debug menu: let Bulwarks, Seekers and Jammers come; let the four events happen; Override as from a crate;
  "An alpha" is one of the stage's own swarm now.
- Still to come (8c): The Warden at 7:30 and The Core at 15:00. Until then the stage is held when the time is
  up.
- Not played by hand yet: all figures are first guesses.

## alpha 0.8.62.16 – 2026-11-23

**Package 62a, part 8a (Luz): Survivor's second stage, AI Takeover: its ground and its first three kinds.**
- **AI Takeover** opens once you have put out The Foreman on Outbreak (the boss at 7:30), and stays open. The
  picture after that run says so. In the fighters' room its tile carries a lock until then.
- **The ground:** a city by night, long after the machines took it. As large as Outbreak's, two broken roads
  across its middle. No lamp is left standing: wrecks burn, the machines' radio masts blink red, tracers of a
  far fight streak over the field. In the way: heaps of rubble with rebar, burnt-out ground cars, rows of tank
  traps, what is left of bunkers, fallen pillars and slabs, barricades; north-east of the middle the wreck of
  a landing ship that came down long ago. Craters, scorch marks and cracks all over the ground. Burning wrecks
  burn whoever stands near; spilled oil holds back whoever walks through it.
- **Enforcer,** the swarm of this stage: the corporations' security robots as the machines run them now,
  matt and dark, plates in the colour of their unit, a red eye. They come all the time, from all sides.
- **Scout** (from 1:30): a machine on four legs, fast, in packs, in a zigzag. Near you it crouches for a
  moment (a mark shows where it will go), then it leaps straight on. Step out of its way, or dodge through it.
- **Gunner** (from 3:00): keeps its distance, takes aim along a red line, then fires three bolts along it,
  standing still meanwhile. Step aside and they pass. Red plates, a long gun: worth putting out first.
- An alpha of this stage is one of these three. Crates, supply drops, your weapons, the console: as on
  Outbreak.
- **The picture before a run** shows the stage in its own colour: what is left of a skyline, searchlights in
  the clouds, tracers, red eyes in the dark.
- Until the next parts: nothing happens by the clock here yet, nobody flies, and no boss stands on this stage:
  when the fifteen minutes are up, the stage is held.
- Fixed on the way: one of the swarm in the middle of what its kind does (a hauler winding up, a spitter
  about to spit) went no further while it stood exactly on you.
- Debug menu: the stage of the next run (Outbreak, AI Takeover); let Enforcers, Scouts and Gunners come.
- Not played by hand yet.

## alpha 0.8.62.15 – 2026-11-23

**Package 62a, part 7c-4 (Luz): Survivor: the Taser, the Blackhole Gun, a share of Coins.**
- **Taser:** a shock into a small field right before you, the way you look, again and again at a short
  interval. Who stands in it is hurt and stunned for a moment (lit yellow, standing still, touching nobody).
  Levels: a wider field, more damage, a shorter interval.
- **Blackhole Gun,** the weapon for the end of a run: it fires a black hole the way you look. The hole drifts
  on towards the edge of the picture and pulls all near it into itself: who reaches its middle is out; the
  tough ones, the alphas and a boss are torn at instead. It fires very rarely (every 28 seconds, down to 16).
  Its card comes from level 10 of a run on, and it cannot be the weapon you begin with. At the console it is
  the dearest weapon (90 cores).
- **Two more boni,** one for each (the pairs and the ultimates are a proposal): **Capacitor** (now and then a
  hit strikes twice as hard: 6 % of the hits a level), **Mass Driver** (what you hit is thrown back further:
  +25 % a level).
- **Two more ultimates:**
  - Taser and Capacitor: **Chain Lightning.** The shock jumps on from everyone it hits to three more near them.
  - Blackhole Gun and Mass Driver: **Event Horizon.** Three black holes at once, spread like a fan.
- **Fine tuning:** "Shards" is called **XP** now (it is the share of what shards bring towards the next
  level); new: **Coins** (+3 % a rank: a run pays more Coins).
- The console shows twelve weapons (six to a row), thirteen boni (seven to a row) and seven rows of fine
  tuning; what the marked tile does may take two lines. The fighters' room shows twelve weapons, six to a row.
- A new stage, **AI Takeover,** is planned: see `Claude outputs/steckbrief_62a_teil8_ai_takeover.md` (not
  built yet).
- Not played by hand yet: all figures are a first guess.

## alpha 0.8.62.14 – 2026-11-23

**Package 62a, part 7c-3 (Luz): Survivor, what is round it. Cores, the console, four more weapons.**
- **Cores:** every run of Survivor brings cores: one for every twenty seconds you held out, two for every
  alpha, twelve for The Foreman, thirty for The Brood. The picture after a run names them.
- **The Survivor console** stands in the Colosseum's lobby, west of the carpet (for the house's fighters: sign
  up first). What cores buy there stays for every run to come:
  - **The arsenal:** weapons and boni to unlock. Only what is yours lies among the cards of a run and can be
    the weapon you begin with. Yours from the first run: Pulse, Laser, Plasma Grenades; Field Amplifier,
    Coolant Loop, Reactor Tuning.
  - **Fine tuning:** small shares for good, ten ranks each: damage +2 %, interval -1.5 %, health +5, pace
    +1 %, magnet +5 %, shards +2 % a rank.
  - **Reroll:** up to three a run. With a new level you draw its three cards anew (R, or the triangle).
  - **Last chance:** very dear. Once a run you stand up again with half your health, and a shock clears the
    ground round you.
- **Four more weapons** (five levels each):
  - **Mine Layer:** lays mines where you walk. One goes off when one of them steps on it. Levels: more mines,
    a wider burst, more damage.
  - **Sentry:** sets down a small gun that fires at whoever is nearest to it for a while. Levels: it stays
    longer and hits harder, later two of them.
  - **Cryo Spray:** a cone of cold the way you walk. Who stands in it is hurt and freezes: stands still and
    touches nobody (the tough ones for half as long). Levels: a longer cone, a longer freeze, more damage.
  - **Gravity Well:** a sphere thrown at whoever is nearest. It pulls all near it to one point and wears them
    down. Levels: a wider pull, it lasts longer, more damage.
- **Five more boni** (five levels each): **Stabiliser** (what you set going lasts longer: blades, mines, guns,
  the cold, the pull, and what a crate gives you), **Overclock** (now and then one more beam, grenade, shot,
  blade or mine: 20 % of the time a level), **Shield Cell** (takes one hit for you, then charges again: 19
  seconds, down to 7), **Scavenger** (shards are worth more), **Lucky Find** (supply drops come sooner, a crate
  holds a level more often).
- **Four more ultimates:**
  - Mine Layer and Stabiliser: **Minefield.** Mines fall in a ring round you, and each arms itself once more.
  - Sentry and Overclock: **Battery.** Three guns that stay for as long as you stay near them.
  - Cryo Spray and Shield Cell: **Absolute Zero.** A wave of frost all round you. What is frozen shatters at
    the next hit.
  - Gravity Well and Scavenger: **Singularity.** At its end it crushes what it has pulled in and sends you the
    shards.
- **The crowd** in the stands goes by the share of what you have unlocked and tuned at the console.
- **The fighters' room:** the stages as tiles (Outbreak; three more still to come), the ten weapons as tiles
  (the ones not unlocked yet carry a lock), your cores.
- **The display in a run** shows the Shield Cell as it charges and the last chance while it is still to come;
  the picture of a new level has the reroll under its cards.
- Debug menu: carry any of the new weapons and boni, all ultimates at once; 100 cores, unlock all, lock all
  again.
- Not as planned: further stages cannot be unlocked at the console yet (there are none to unlock); Overclock
  gives its "one more" a share of the time, not always.
- Not played by hand yet: prices, figures and how the new weapons feel are a first guess.

## alpha 0.8.62.13 – 2026-11-23

**Package 62a, part 7c-2 (Luz): Survivor, the stage. Outbreak comes alive.**
- **Seven more of the swarm,** each with its own way and its own picture:
  - **Runner** (from 1:30): fast and weak, in packs from one side, in a zigzag. A courier in full flight, a
    satchel on the back.
  - **Hauler** (from 3:00): takes a great deal. Near you it winds up (a ring on the ground fills), then it
    stamps: you are hurt and thrown back. A dodge at the right moment takes you through. A dock worker grown
    into the frame of a loader.
  - **Spitter** (from 4:30): keeps its distance; its neck lights up green, then it spits a slow ball of acid
    that leaves a pool for a moment.
  - **Bloater** (from 6:00): slow. Put out, it bursts into a cloud of poison that stays for some seconds.
  - **Shieldbearer** (from 8:30): a hit does not throw it back, and its shield takes the damage until it
    breaks. The superlaser breaks the shield at once.
  - **Howler** (from 9:30): stands and howls, and all near it walk faster. Worth putting out first.
  - **Alpha** (once a minute): a great one of a kind that has come by then, in a light of its own, a mark and a
    bar over its head. It takes ten times as much and leaves a great shard and a crate.
- **What happens by the clock,** each announced with a word across the picture:
  - **The Flock** (from 2:30, about every 45 seconds): screechers, old survey drones the sickness has grown
    over, fly in a wedge straight through you, over all that stands in the way. Arrows at the edge say where
    they come from.
  - **The Ring** (4:00, and again at 12:30): a circle of the swarm closes round you.
  - **They Rise** (5:30): those who lay in the colony all along get up when you come near.
  - **The Wall** (10:00, and again right after the second ring): a dense row comes over the field from one side.
  - **Blackout** (11:00): the lamps go out for twenty seconds. You see little more than their eyes.
  - **Supply drop** (from 2:00, about every two minutes): a crate comes down, an arrow at the edge points to it.
- **Crates:** eighteen stand about the colony, every alpha leaves one, supply drops bring more. Touch one and
  it opens: mostly an item, now and then a level of something you carry.
  - **Shield** (nothing touches you for six seconds), **Magnet** (every shard on the field flies to you),
    **Medkit** (35 health back), **Atomic Bomb** (all in a wide radius are out; an alpha and a boss take a heavy
    blow), **Stasis** (they stand still for four seconds), **Overdrive** (your weapons fire twice as fast for
    eight seconds).
- **The Foreman** (7:30): the foreman of the shift in a battered loader's frame. Walls of light grow round a
  field about you and it: to touch them hurts and throws you back. The swarm that is there stays; nobody new
  comes while the walls stand. It charges along a line it shows first, strikes the ground (a ring of force to
  dodge) and throws containers onto marks. Out, it leaves a great crate (a level of something you carry), and
  the walls fall.
- **The Brood** (15:00): when the time is up the clock stands and the last one comes, a mound of flesh with
  sacks. Three parts, by what is left of it: rings of acid with a gap to slip through and shamblers it lets out;
  then two arms of acid turning round it, and runners; at last both at once, and the flock. Put it out and the
  run is won.
- **Sounds for Survivor** (made by the game itself, quiet): the weapons, hits, shards, crates, items, a new
  level, the stamp, the spit, the howl, the alarms of what happens.
- **The display** shows a boss's name and what is left of it, what a crate gave you for as long as it lasts, and
  arrows to crates that came down.
- Debug menu: let any kind come, let anything happen, both bosses, whatever a crate can hold.
- Not as planned: an alpha has a light of its own, a mark and a bar in place of a glowing spine.
- Not played by hand yet: how hard it is and how it feels are open, and nobody has heard the sounds.
- Still to come (part 7c-3): four more weapons and five more boni, what stays of a run for the next ones (cores,
  the console in the lobby), the choice of stage.

## alpha 0.8.62.12 – 2026-11-23

**Package 62a, part 7c-1 (Luz): Survivor, the look.**
- **Five places** for weapons and five for boni (not six). There is more to carry than places, so you choose.
- **The shards** are small cells of energy now: crystals with six sides and a core of light, hovering a little
  over the ground, each in its own glow in the dark. Their colour says what they are worth: cyan, green, gold,
  magenta. One on its way to you draws a short trail of light.
- **The cards of a level** are larger and say more: a frame of light in the colour of the kind (a new weapon
  green, a weapon's level cyan, a bonus gold, an ultimate in all colours), brackets at the corners, a grid of
  light behind, the sign in a six-sided frame with rings turning round it, the levels as lit points. A card says
  in figures what it changes ("Radius 44 → 52", "Interval 1.4 s → 1.25 s") and what it fuses into ("Fuses with
  Field Amplifier into Nova Field"; brighter once you carry the other half).
- **The display in a run:** the shards towards the next level as a bar of segments with your level in a
  six-sided plate, the clock on a plate of its own, your health in segments, the places for weapons and boni
  framed in light (a weapon that is its ultimate in all colours).
- **The picture before a run (Luz):** you at the left; the right half is split: above, the stage (its name, a
  picture of the colony by night under the ringed giant, its dangers, how long it lasts); below, the weapon you
  begin with and what it fuses into.
- The picture after a run got the same frame.

## alpha 0.8.62.11 – 2026-11-23

**Package 62a, part 7b (Luz): Survivor, the arsenal. And the entrance before a run.**
- **The entrance (Luz):** a run of Survivor begins like a fight after all: out of the white at the fighters' gate,
  the crowd claps you in, the camera rises over the round. Nobody walks in across from you; in place of the
  "versus" the picture shows you and the weapon you begin with. Then the hologram comes up and you stand in the
  stage. From the second time on, holding Esc or Options goes straight in.
- **The crowd in Survivor** goes by how far you have come in that mode, not by your rank or a run of wins. Until
  the mode has its own way of getting on from run to run (part 7c), that is your best time and how often you have
  played.
- **Your first weapon is yours to pick:** six tiles in the fighters' room.
- **Four more weapons** (five levels each, like the two before):
  - **Plasma Grenades:** thrown near you, at one of them if one is near; each bursts where it lands and hurts all
    round it. Levels: more grenades, a wider burst, more damage.
  - **Drone:** a ring of shots round you, all ways at once; each stops at the first it meets. Levels: more shots,
    a shorter interval.
  - **Superlaser:** a mighty beam sweeps a quarter of the round, somewhere. What it touches is out. It fires
    rarely. Levels: a longer beam, a shorter interval.
  - **Silverblade Drone:** darts away from you, cuts what it touches, bounces at the edge of the picture and
    darts back at you. Levels: it lasts longer, cuts deeper, more of them at once.
- **Six boni** (five levels each), cards like the weapons: Field Amplifier (wider fields and bursts, longer
  reach), Coolant Loop (shorter intervals), Reactor Tuning (more damage), Magnet Coil (shards fly to you from
  farther off), Nanite Weave (more health, and it comes back slowly), Servo Frame (you walk faster).
- **Six ultimates:** a weapon at level 5 whose own bonus you carry becomes its ultimate. The card lies on the
  table for sure once it is ready.
  - Pulse and Field Amplifier: **Nova Field.** The field stands for good, burns without a pause and slows all in it.
  - Laser and Coolant Loop: **Prism Array.** Every beam jumps on to two more of them.
  - Plasma Grenades and Reactor Tuning: **Plasma Rain.** Grenades fall all over the field you see.
  - Drone and Magnet Coil: **Carrier Swarm.** Two rings at once, and the shots go through whoever they hit.
  - Superlaser and Nanite Weave: **Sunlance.** The beam sweeps the whole round.
  - Silverblade Drone and Servo Frame: **Silver Storm.** The blades stay for good and circle you.
- The display shows the boni in their places; a weapon that is its ultimate is framed in pink.
- Still to come (part 7c): more of the swarm (giants, flyers and the rest), events, the stage's last opponent, the
  choice of stage, more weapons and boni than places, and what stays of a run for the next ones.

## alpha 0.8.62.10 – 2026-11-23

**Package 62a, part 7a (Luz): Survivor, the core. A game inside the game.**
- **The mode is open.** In the fighters' room, Survivor shows its stage, how it goes and your first weapon; the
  house's gear plays no part there (the fit is veiled). READY takes you straight into the stage: no entrance, no
  opponents to show.
- **The stage, Outbreak:** a colony under quarantine, by night, as a hologram about six times the size of a
  fight's ground. Two roads cross in its middle, lamps along them. No cover here: what stood in the colony stands
  in your way and in theirs, in loose groups with wide lanes between: cargo containers, parked rovers and
  loaders, greenhouse domes, silos, gas tanks, stretches of the quarantine's fence. Wrecks still burn (the embers
  round them burn whoever stands there) and split tanks have spilled coolant (it holds back whoever walks
  through it). The pad in the middle ends the run by your own choice.
- **The swarm:** the shamblers, those of the colony who still walk. They come from just outside the picture, from
  all sides, slowly at first and then faster and faster; the longer the run, the more each of them can take. They
  walk straight at you, slide along what stands in their way and push each other apart. Up to 450 at once.
- **Your weapons fire by themselves.** You walk, and you dodge (the dodge key): a quick step during which nothing
  touches you; two of them, each back after three seconds. Two weapons for now:
  - **Pulse:** a field round you that hurts all in it, again and again. Levels: a wider field, more damage, a
    shorter interval.
  - **Laser:** a beam at whoever is nearest. Levels: more beams at once, more damage.
- **Shards and levels:** who is put out drops a shard of light; shards near you fly to you. Enough of them make a
  level: the run stands still and you take one of three cards (mouse, 1 / 2 / 3, or left / right and Enter): a
  new weapon, or a level of one you carry (five levels each; six places for weapons, six for boni). When there is
  less than that to offer, a med cell and a purse of Coins fill up.
- **You:** one bar of health. A touch costs some, then nothing can hurt you for a moment. No energy, no rounds,
  no charging points here.
- **The end:** you are out, or you hold the stage for its fifteen minutes. A run pays Coins and rank points by
  the time you held out and by who you put out (half as much again for holding the stage). Your best time is kept
  and stands on the mode in the fighters' room.
- Still to come (parts 7b and 7c): the other four weapons, the boni and the ultimates, more of the swarm (giants,
  flyers and the rest), events, the stage's last opponent, the choice of stage and first weapon, and what stays
  of a run for the next ones.
- Debug menu: start a run, +1 level, +100 of the swarm, +1 minute, end the run.

## alpha 0.8.62.9 – 2026-11-23

**Package 62a, parts 5 and 6 (Luz): more grounds for the fights, Team Deathmatch, and the orders for your team.**
- **Six settings** instead of three. New: **Jungle Ruin** (trees, old stone), **Lava Field** (black rock, barrels,
  red light), **Neon Yard** (a back lot of the city by night under coloured light).
- **Four ground plans,** mixed with every setting by lot: an open field (as before), a canyon (two long walls
  across the field with three gaps each), a fortress (a ring round the middle with a gate on every side, pieces of
  an outer ring), three lanes (two strips from north to south with two crossings each). The walls are rock in the
  wild settings and bulwarks in the yards. That makes 24 grounds, each of them different every time.
- **Every setting has a danger of its own,** named when the fight begins and in the fighters' room:
  - Dust Canyon: dust devils rise here and there on the field and hide whoever stands behind them.
  - Glacier Shelf: sheets of bare ice. You slide on them.
  - Container Yard: plates under current that pulse on and off (their rim blinks before they come on).
  - Jungle Ruin: undergrowth that holds you back.
  - Lava Field: fields of embers that burn whoever stands on them. In three lanes, the strips are streams of lava:
    no way across, but you see and shoot across.
  - Neon Yard: steam vents that burst in turn and hide the lot round them.
  The ground works on everybody alike: the others and your team slide on the ice and are held back by the
  undergrowth as you are, and what burns, burns all of you. They know the ground: their ways lead round what
  burns, nobody picks a spot on it, and who finds themselves standing on it gets off.
- **Team Deathmatch is open:** three against three strong ones. In the fighters' room you pick the two who stand
  beside you from a list (a click sends one away or calls one in; with a place free you are not ready). For now
  the list holds **Rook Varga** (quality C from the start) and **a chance acquaintance of the arena** (quality F,
  a name and a face by lot, kept in your save). Their quality is where they begin and how fast they grow: with
  your rank and your wins in a row they get better, Rook faster than the other.
- Your two walk in with you, stand beside you in the picture before the fight and fight in the house's light
  combat suit. Who is shot down is out for this fight.
- **They live on energy and rounds as you and the others do:** a shot costs them what it costs you, their shield
  draws energy to recover, and who runs dry runs to the nearest charging point that is ready and draws it dry.
  Their cards show both beside shield and body.
- **The orders for your team (part 6):** in the Colosseum the command wheel has six fields in place of the crew's
  four (the key is the same: tap for whom, hold for the wheel):
  - **Follow me:** beside you, fighting near you (as before).
  - **Your call:** they go at whoever is nearest by their own way of fighting, look for cover by themselves when
    badly hurt and fill up when nearly dry and nobody is near.
  - **Right wing / Left wing:** along their own line to the side of the field, up that side to where the others
    are, then at them from the side. If one of the others stands in their way before that, they fight.
  - **Hold in cover:** into the nearest cover against the others, and they stay there and shoot from it. They
    move only when that cover no longer covers them.
  - **Fall back:** back to where you came in and into cover there; low on energy or rounds, they fill up at a
    charging point on the way.
  The card of each shows the order it is on. Once you are out, each of them is on their own call.
- **Lost only when your whole team is out.** If you go down while one of yours still stands, the picture stays
  with your team and the others turn on them. You can watch it to the end, or end it with E: the rest is then
  worked out from what both sides still have.
- **Every mode has a run of its own** (its round, its wins in a row, its gear points and its fit). The rank is
  shared. A win in Team Deathmatch pays half as much again in Coins and rank points.
- No crew of your own comes into the hologram any more (the house's rules).
- Debug menu: pick the next fight's ground and plan, or leave them to the lot.

## alpha 0.8.62.8 – 2026-11-23

**Package 62a, part 4 (Luz): the fight. King of the Colosseum, and the rank.**
- **The entrance:** out of the white you stand at the fighters' gate in the house's gear. The camera rises over the
  whole round and comes down again; across from you the gate slides open and the three walk in; then the picture of
  them against you (the strong one large in the middle, you in the suit you chose, "VS", the mode and the round);
  then the hologram comes up: cover of light grows out of the tiles. The first time you see all of it; after that
  holding Esc or Options goes straight to the fight.
- **The fight's ground:** the arena builds whole maps as holograms, far larger than the arena itself. Three
  settings for now, drawn by lot: Dust Canyon, Glacier Shelf, Container Yard. You begin in the south, the three in
  the north, cover all over the field; a wall of light runs round it. "3, 2, 1, FIGHT".
- **The fight:** against one strong and two weak fighters, drawn by lot from the arena's list, in the house's gear
  (your own is put by and stays yours in the save). Every round all three are a little better. Every tenth round a
  named opponent stands in the strong one's place: The Warden, Old Mercy, Glass Saint, The Last of Kiln. Nobody
  dies: who is shot down is out. The pad where you begin lets you give up, which counts as lost.
- **A win** pays Coins, gear points and rank points (three times the Coins for a named one). Then: the next round
  (straight back into the fighters' room), or stop for now: your run stays as it is.
- **A defeat** ends the run: its gear points go back to the house, the round is 1 again. Your rank stays.
- **The rank** stays, whatever the mode: Newcomer, Contender, Gladiator, Champion, Legend. Every rank gives you 2
  more gear points to begin a run with and one quality more that the house hands you (F and E at first, up to A).
  It stands in the fighters' room, in the picture after a fight and on the ranking in the lobby.
- **The crowd:** the stands are fuller the longer your run and the higher your rank. It claps when you come in,
  when the three come in and when you have won: the fuller the stands, the louder.
- **Energy:** five charging points stand spread over every fight's ground. One fills your energy and your
  ammunition and is then drawn dry for 25 seconds (a ring of light shows when it is ready again). The three live
  on their suit's energy and their rounds as you do: a shot costs them what it costs you, their shield draws
  energy to recover, and who runs dry cannot shoot and runs to the nearest point that is ready. So a point you
  draw dry is one they cannot use.
- The three know where you are from the first moment and do not lose you.
- Debug menu: +100 rank points, win or lose the fight at once.

## alpha 0.8.62.7 – 2026-11-23

**Package 62a, part 3 (Luz): the way into the arena.**
- **The Marshal of the Lists:** the one at the registration has a name and a face now: Cass Ardent, who fought in
  the arena once. You talk at the counter (what the Colosseum is, its rules) and answer "Register"; from the second
  time on the answer is "Compete".
- **The way to play:** a choice of four opens every time: singleplayer, online co-op, online versus, split screen.
  Only singleplayer is open; a band "COMING SOON" lies across the other three.
- **Through the gate by itself:** the game walks you round the counter, through the gap and into the fighters' gate
  (the first time the fighters' area opens in its scene before that); the picture goes dark.
- **The fighters' room:** one window. Left your gear: the places of a suit as in your own gear window, filled with
  the house's pieces (suits, weapons, grenades, things for the belt, modules, drones), never with your own. Every
  piece costs **gear points** by what it is and by its quality; the points are a budget: what you take off gives
  its points back, so you may fit yourself anew before every fight. You begin with 10. In the middle the pieces
  for the place you marked, the cheapest first. Right the modes: King of the Colosseum is open, Team Deathmatch and
  Survivor wait under "COMING SOON". Once a mode is picked: who waits in the arena (one strong, two weak), your
  record, what a win pays.
- **READY** counts down from five (Esc calls it off until two), the picture goes white, and you stand in the arena:
  a great oval of white tiles inside its wall, the tiers and the crowd all round, the wave of blue light running
  over the floor. There is no fight yet: the fighters' gate in the south leads back into the lobby.
- Every choice (the way to play, a piece of the fit, the mode, ready) goes through the command bus by seat.
- Debug menu: the arena, +5 gear points.

## alpha 0.8.62.6 – 2026-11-23

**Package 62a, part 2 (Luz): the Colosseum's lobby, its stands, the arena at rest.**
- **The great gate is open.** Behind it a high hall of marble with strips of neon. A red carpet with cords of
  velvet runs from the gate straight to an open gate ahead that leads onto the stands; four figures of earlier
  champions stand either side of it, each with its name and the year of its title. On the west wall the ranking.
- **The registration:** a counter of marble with one of the house. You sign up once, free, under your pilot's name;
  your name goes on the ranking.
- **The fighters' gate** stands behind the registration, in an area shut off by screens of marble and a wall of
  light. When you have signed up, a short scene plays: the camera goes over, the wall of light flickers and falls
  apart, the gate slides open (use or Esc ends it at once). From then on the way in is free. Beyond the gate lie
  the fighters' rooms: the gear for the rounds will be fitted there once the fights are built.
- **The stands:** rows of seats going down to a walk along a rail of glass; guests sit there. Every row is a seat:
  from a seat the camera looks down into the arena. The rest of the round with its crowd, the dome from inside
  and the screens over the arena are drawn.
- **The arena at rest:** a floor of white tiles. Every few seconds a wave of blue light runs over it (a line
  across, or a ring from the middle); now and then the system tries itself and holograms of cover flicker up out
  of the tiles and fall back into them. You cannot walk onto it yet.
- The screen on the plaza, in the lobby and over the arena shows the same card. Debug menu: lobby, stands, signed
  up or not.

## alpha 0.8.62.5 – 2026-11-23

**Package 62a, part 1 (Luz): the plaza before the Colosseum.**
- **Line B leads somewhere now:** the stairs of the station Colosseum are open and lead up onto a plaza of its own.
  It is built like the plaza of the Commercial District (the same way down to the metro, drawn house fronts, the
  roofs of tall buildings in the south), with far more marble: great slabs with joints of gold, a round mosaic,
  two long basins with jets, bowls of holo fire, cypresses, stalls, banners of the champions.
- **Colossi:** four figures of marble on plinths, about three times a person's height, and two greater ones at the
  grand stair: the arena's champions in their combat suits, each with a blade of light in its own colour.
- **The Colosseum:** a giant round of marble north of the plaza, four rings of arches, strips of neon running
  round between them and climbing its piers, pulsing; a dome of holograms over the arena, floodlights on its crown.
  It is far larger than the picture: from the plaza you see its foot (near it the camera looks up at it).
- **The screen over the gate** announces the next fight: a fighter in a combat suit is pushed in at the top right,
  then "VS", then the other at the bottom left, their names and the mode. The pairings are made up for now.
- **The viewing scope** on the plaza pulls the view back until the whole Colosseum stands in it, Lapis behind, the
  city small beside it; at night beams of light and fireworks.
- **The Laurel:** a very fine house of residences west of the plaza, with a doorman. Apartments will be for sale
  there later; its door is shut for now. The Colosseum's gate is shut too: the inside follows.
- Debug menu: "Colosseum plaza".
- Smoke test: the groups set in Beyond dock at a station first when a group before left you landed on a planet
  (that was why the two checks of package 59 failed in a full run only). A full run is green again.

## alpha 0.8.62.4 – 2026-11-22

**Package 62b (Luz): the bets on The Track.**
- **The races:** three dangerous courses in the Fern system take turns: The Kiln Run (the lava canyons of Kiln),
  The Ring Dash (the rings of Lapis) and The Belt Slalom (the asteroid belt). Six of a stable of twelve racing
  pilots fly each race, every one with a ship, a skill and a taste for risk: who risks more is faster and wrecks
  more often. A wreck is a wreck, the pilot is picked up.
- **By the clock:** a race every five minutes, whether you are there or not; bets are taken until it starts. The
  screen on the wall of The Track shows the race as it runs, before it the card of the next one, after it the result.
- **The counters are open:** the card of the next race with every pilot's last races and the odds. Three kinds of
  bet: win, place (among the first three) and exacta (the first and the second in their order). Chips of 1, 5, 25
  and 100, at most 500 Coins a race; a ticket is final. The odds hold the house's share.
- **A seat in the cinema:** sit down in a row and the race is large before you, with the standing, the speaker's
  word and your tickets. You can wait for the start and skip to the end.
- **Paid at the counter:** tickets that are decided are paid when you next come to a counter, and go into the
  house's books on you.
- **A kind hand:** with the perk Lucky Hand the clerk tells you who is in good form today. The race is never touched.
- The odds boards in the room show the chances of the race that takes bets. Built for co-op: every ticket belongs
  to a seat, every bet goes through the command bus.

## alpha 0.8.62.3 – 2026-11-22

**Package 62, part 3 (Luz): blackjack and poker.**
- **The house's cards:** a deck of 52 in the four suits of Drift (comets, moons, suns, nebulae), 2 to 10, then the
  Pilot, the Captain, the Admiral and the Ace; dark cards with an edge of neon.
- **Blackjack** at the three card tables of The Tables and at the high table of the VIP lounge: set your stake
  (chips of 1, 5, 25, 100, the limit 500 Coins a hand; at the high table 100, 500, 2,500 and 25,000), have the cards
  dealt, then take a card, stand or double. The house draws to 16 and stands on 17; a blackjack pays 3 to 2, a
  stand-off gives the stake back. No splitting, no insurance. Two guests play their hands beside you.
- **Poker** at the oval table of The Tables and at the high table of the lounge: Hold'em without a limit against
  three guests. You buy in for 100, 200 or 500 Coins (5,000 at the high table), the blinds go by the buy-in; fold,
  check or call, raise with the slider, go all in; side pots when a seat is all in. You stand up between the hands
  (or once you have folded) and take your chips along as Coins; out of chips you buy in again or leave. The house
  takes 5 per cent of a pot that has seen the flop (at most 25 Coins, 1,000 at the high table).
- **Who sits there:** the guests at the poker table have a name, a trade, a way of playing (careful, loose, a
  bluffer) and a strength; one without chips makes room for the next. Once you have crossed the Veil, **Rook** and
  **Dan** sit at a table now and then; a sitting with them brings you a little closer, like a bar game.
- **A kind hand:** at blackjack a card that would take you over 21 slips back for the next now and then; at poker
  you read a tell of one of the guests in some hands (strong, weak, nothing). Both grow with Dexterity and with the
  perk Lucky Hand. The cards at poker are never touched, and the house keeps its edge at blackjack.
- **Built for co-op:** a free seat at both tables; every stake and every move goes through the command bus with the
  seat's number.
- What you win and lose at both goes into the house's books on you at the cashier.

## alpha 0.8.62.2 – 2026-11-22

**Package 62, part 2 (Luz): the machines and the wheel.**
- **Slot machines** on the floor The Machines: sit down at a row and its machine opens (Lucky Lapis, Comet Rush,
  Kiln Gold), loud with neon. Three reels, one line; the stake is 1, 5 or 25 Coins; Space pulls. Three alike pay
  8 to 250 times the stake (ore, fuel cell, comet, star, ring of Lapis, Coin, holo seven), the first two alike pay
  twice. No automatic spinning.
- **The house's jackpot** grows with every spin (and slowly by itself while the house plays on); three Coins at the
  highest stake take it. The counter on the wall of The Machines shows it as it stands.
- **Roulette** at the two tables of The Tables and at the high table of the VIP lounge: a wheel of light with 37
  pockets, the ball a point of light. Pick a chip (1, 5, 25, 100; at the high table 100, 500, 2,500), click a
  field of the cloth, a right click takes the bet back: single numbers (35 to 1), red and black, even and odd,
  the halves, the dozens and the columns. The limit is 500 Coins a spin, 25,000 at the high table. "Same again"
  puts your last bets back.
- **Others play too:** two guests sit at every roulette table and bet in their own colours; guests stand at every
  table of The Tables and of the lounge. One seat at the wheel stays free for a co-op player: every bet and the
  spin go through the command bus with the seat's number.
- **A kind hand:** a pilot's Dexterity makes the games a little kinder (a machine's middle reel slips into a pair
  now and then, the wheel's ball hops one pocket on when that is better for you), and so does the new perk
  **Lucky Hand** (Commerce). The house keeps its edge all the same.
- The cashier tells you the house's books on you: Coins staked, Coins got back, your best single win.

## alpha 0.8.62.1 – 2026-11-22

**Package 62, part 1 (Luz): the Grand Centauria from inside. The building first, the games follow.**
- **The casino is open.** The stair on the plaza of the Commercial District leads into the middle tower. Six floors
  lie one over the other, their halls narrower the higher, joined by capsules of glass on the tower's outside (the
  lifts' window lists the floors by number):
  1. **Lobby:** marble, gold and violet, the house's name in lamps, a chandelier of light over a fountain with a
     Coin of light turning above it, an inlay of gold in the floor, a red carpet between ropes of velvet, reception,
     the cashier, sofas, palms, attendants at the doors.
  2. **The Machines:** three rows of slot machines, their reels turning, a jackpot counting over them.
  3. **The Tables:** two roulette tables, three for blackjack, one for poker, their dealers behind them, and a table
     for Drift (that one can be played already).
  4. **The Track:** a small cinema: a great screen with a race running on it, rows of seats, boards of odds, two
     betting counters (their shutters still down).
  5. **The Aurum Bar:** dark wood, a long counter under the glass, a grand piano (somebody plays at night), sofas.
     A meeting place for now.
  6. **VIP Lounge:** in the tip, a club for the Cluster's one per cent, members only (the lift refuses you for
     now). Its hall is dark and loud: a bar, a DJ, a dance floor of light between platforms on which the house's
     dancers dance, booths in velvet, Lapis turning as a hologram, and along the south the three high tables
     (roulette, blackjack, poker) on a carpet of their own. Through a wall of glass lies the terrace: it juts out
     beyond the tower's wall, a pool to its very edge with members swimming in it, sofas that look out over it at
     Lapis, a pool bar, loungers at the south edge, fire in bowls, palms, two more platforms with dancers. Round it
     the sea of cloud from above, Lapis huge over it. The terrace follows day and night, the hall stays a club.
     Its guests wear the coats and jackets of the rich; the house's own wear its livery on every floor.
- **The lifts** are capsules of glass in tubes on the outside of the tower, two on every floor, beside them a row of
  lamps that shows the floor. Choose a floor: you walk to the nearest capsule, its doors of bent glass slide apart,
  you step in and they shut. Then the picture goes outside: the capsule runs up or down the tower to that floor's
  height. On a long ride the view pulls back until the whole towers stand in it and closes in again where the
  capsule stops; the floors hang beside the rails as names, yours in gold, the other capsule comes the other way.
  The interact key skips the ride. Out you step on the other floor.
- **The view** through the wall of glass grows with the floor: the city's skyline sinks, Lapis grows, from the bar
  up you look down on the clouds. It follows day and night.
- **Coins**, the money of the Grand Centauria: the cashier in the lobby sells them (100 cr each) and changes them
  back (95 cr each). They are saved with the game and shown in the casino's title line. Later they also pay for
  special paints, services and gear in the Colosseum.
- The machines, tables and betting counters stand there but are not played yet: parts 2 and 3 and package 62b.
- Debug menu: the Grand Centauria: straight to any floor (the lounge makes you a member), the membership on and
  off, 1,000 Coins.

## alpha 0.8.61.5 – 2026-11-22

**Package 61d (Luz): the Museum moves to Centauria; Second Skin, paint for your ships.**
- **The Museum** stands in Centauria now and only there: the Museum of Centauria, on the west plaza of the
  Commercial District. Its rooms, its 48 cases and its curator are as they were. The city on Curie has an ordinary
  roof plaza again. (Later, in the story: Dr. Imre Halden opens it.)
- **Second Skin**, a paint shop only in Centauria, in the west pavilion of the Commercial Hall: an open showroom
  with small ships turning on pedestals. Its window (Paint Shop, Second Skin): your ships that stand in Centauria's hangar, the picked ship
  in the picked paint, thirteen fixed paints (Midnight and Gold, Bone and Blood, Lapis, Pelagia, Kiln, Glacia,
  Ember, Neon Alley, Static, Grand Centauria, Hazard, Ghost, Rust Bucket).
- A paint fits every hull, because it is a scheme for the colours all ships are drawn from; a ship's drones wear it
  too. The price goes by the hull's size (2,500 / 8,000 / 20,000 cr, larger hulls 40,000 cr, after the standing),
  Rust Bucket at half of it; back to the factory's colours is free.
- Debug: the Museum's buttons fly to Fern and land in Centauria.

## alpha 0.8.61.4 – 2026-11-22

**Package 61b (Luz): the Back Alleys and the Static Feedback. Places and people only: the story comes later.**
- **The gate** in the south of the plaza is open. Behind it lies a street of its own.
- **The Back Alleys:** a narrow street running east and west between high houses, dark even by day. Along its north
  side front after front: noodle bars open to the street (cooks, lanterns, steam, stools at the counter), small
  shops behind bars, shutters with scrawls, an arcade; over them signs in layers, screens, cables. Along its south
  side the roofs and awnings of the shops there, their light on the street. The street is wet and the neon lies in
  it. Lanterns on lines cross it, now and then a craft passes overhead with a searchlight.
- **The crowd:** people stream east and west through the street, close together, with umbrellas when it rains. At
  the street's ends they are gone and others come in.
- **The Static Feedback**, Luz' punk bar, lies in a cellar at the street's east end: down the stairs under its sign.
  A small place: dark wood, brick, bills and stickers, haze, neon everywhere. A little stage, a short counter with
  its shelves of bottles, two booths, pool, darts, an arcade cabinet, a Drift table, the jukebox, a door to a back
  room (shut). Nobody strolls in here and no crew is hired: it is where the people of the story meet, and your own
  crew waits here (those of your ship who do not come along on foot).
- **The band** plays only at night: The Hull Breach, four real people on the stage (Vex at the microphone, Solder
  on guitar, Flux on bass, Tin on the drums), and a few dance before them.
- **Luz** stands behind the counter, always (unless the story says otherwise later), and no longer on the plaza.
  "A Place Called Fern" leads to the bar now. Two regulars, a little shady, stand by the booths: **Ratte** and
  **Kraut**. All three have a few words; no tasks yet. Ratte and Kraut join the acquaintances with the story.
- Seen so far only in test pictures at night and in rain.

## alpha 0.8.61.3 – 2026-11-22

**Package 61a, the rest (Luz): the Commercial Hall from inside, Centauria's landmarks in the approach.**
- **The Commercial Hall** is a great gallery under a vault of glass now, as its front promises. Along the north wall
  every service of the city has a shop front of its own (its name, windows full of goods, a door of glass); over them
  two galleries with shops and people walking, the vault with the sky and Lapis behind it, lights on lines.
- In its middle a fountain with a hologram of Lapis turning over it, kiosks, benches, palms, pillars of light; a food
  court to the south-west; two pavilions "to let" to the south-east (special shops move in later); escalators up to
  the galleries at the east end (closed for now). No rain in there.
- **Ways:** you walk in and out through the Hall's doors on the plaza. Its lifts (west end, a row of terminals beside
  them) know only the Hall's own floors (the clinic, the quarters, the maintenance level when there is work down there). The back alley is gone from
  the list (the Back Alleys get a map of their own) and so is the tower bar (a punk bar and the casino's bar are to
  come), so until then Centauria has no bar to hire crew in.
- **The approach:** flying down to Centauria you see the three towers of the Grand Centauria (by day round stepped
  roofs in the city's tone with long shadows, by night rings of the city's own lights, some in each tower's colour)
  and the Colosseum (a white oval round its arena, banners; floodlit by night). Both stand on the city's island.
- Seen so far only in test pictures at night. Still open: a look at it all by day.

## alpha 0.8.61.2 – 2026-11-21

**Package 61a: Centauria by hand (Luz): its trains and the Commercial District. The place you will spend the most
time in, so it is drawn in far more detail than any city before.**
- **The trains:** the hangar's lift now leads only to the station Centauria Central. Two lines run to a timetable
  (15 s at each stop, rides of 21 to 25 s): Line A to the Commercial District, Line B to the Colosseum (its station
  stands, the way up opens later). Screens over the platforms count the seconds; sleek trains come out of the tunnel,
  their doors slide. More districts can be added as further lines.
- **The ride:** you stand in the car (seats along both walls, grab poles, three doors that all work, a screen
  "ARRIVAL n s"). Outside: the station drifting off, the tunnel, about 15 s of the city (the casino's towers or the
  stadium, the sea, Lapis large behind it all), the tunnel again, the next station.
- **The Commercial District** after Luz's sketch, one wide map: the central plaza with the way down to the metro in
  its middle (lit steps, a board with the next train in seconds), fountains, holo statues, pillars of light, stalls,
  benches, palms; west the Museum's plaza as it stands on Curie; east the Commercial Hall with a plaza of its own,
  a café and a market row. The Hall holds the city's shops (ship services stay at the hangar).
- **The Grand Centauria:** three giant towers of dark glass north of the plaza, the highest buildings of the city
  and far higher than the screen, on a podium with a terrace and a broad stair. Closed for now ("opening soon").
  They and the skyline shift against you as you walk.
- **The viewing scope** on the plaza pulls the view back until the whole towers stand in it: the city small at their
  feet, a layer of cloud, traffic in the air, at night lasers and fireworks, Lapis behind.
- **The houses round the plaza** are drawn at the scale of the people: shops with a door you could walk through,
  goods and somebody inside, awnings, neon names; storeys with framed windows, blinds, curtains, balconies, washing
  on a line; upright signs, changing billboards. The Commercial Hall: a great arch of glass with galleries and
  people, its name in lights, a ticker, a glass dome.
- **The south:** the roofs of tall buildings come up from the bottom of the picture in two rows (water towers,
  penthouses, pools, gardens, a bar with guests, billboards, landing pads, drones over them), so the plaza lies
  wrapped in the city. Between two of them a gate with the sign of the back alleys; barred for now.
- **Lapis** stands large in Centauria's sky, drawn in detail: bands, drifting storms, a dark spot, a soft night side,
  rings in many bands with the giant's shadow across them. It has two more moons, **Ember** (lava) and **Glacia**
  (ice); the scope shows them. Lapis may have a cloud city again.
- Luz now waits on the central plaza, by the way up from the station (the journal says so).
- Seen so far only in test pictures at night and in rain. Still open: the island in the approach and on the planet
  map, the inside of the Commercial Hall (still the old shopping street), a look at it all by day.

## alpha 0.8.61.1 – 2026-11-21

**Package 61: the Fern system (Luz). Fern is to become the home system; its city Centauria follows piece by piece.**
- **Fern** lies out in the Rim and belongs to no one (independent, security 0.6): a red giant, the lava world Kiln, an
  asteroid belt (always there), the ice giant Lapis and its ocean moon Pelagia. The Rim's waystation stands in orbit.
- **Lapis** has a look of its own: a deep sapphire blue, wide bright rings in three bands with clean gaps, the planet's
  shadow on them. No cloud cities there: all of Fern is in Centauria.
- **Centauria** is Pelagia's one city, for now built like any city (a placeholder until the hand-made one).
- **Rook's call** at pilot level 5: a place in the Rim with more work than a pilot can handle, and a contact, Luz.
  Journal: "A Place Called Fern" (fly to Fern, land in Centauria, find Luz).
- **Luz** waits on the street of Centauria, says hello and joins your acquaintances (a short description, likes).
- Debug: "To Fern (package 61)", Story tab "Package 61: Rook's call now".

## alpha 0.8.60.1 – 2026-11-21

**Package 59: the way to the Cluster, and package 60: acquaintances (Luz). Both complete. The intro ends here: the
open game begins.**
- **The morning after the party:** Dan calls you up to the bar (a call of the usual length; the task stands in the
  journal). The bar is closed: Dan and Dr. Imre Halden of the Meridian Directorate by the window, Imre's Threshold
  parked beside the station. Come close and the talk starts. Imre waits for you: "Time to leave..." or questions
  about the Cluster, the Assembly, the Covenant and the Directorate.
- **The farewell:** "Ready to leave Beyond?", then Dan's hangar: Dan, Ossa and Silas in the walkway under the glass,
  Little Darling behind it, Rook at your side. Rook comes along. Imre walks over: Assembly or Covenant, each asked
  once more (`start_faction`).
- **The Threshold's jump:** Imre explains the ship on the radio, its core ignites, "Hold on tight. Here we go.", and
  the ship swirls into the black hole in its own middle like a whirlpool; the hole collapses with a flash and a purple
  ring. The arrival is the same backwards.
- **The naturalisation:** you arrive at your first station (the Assembly's border system, or the Covenant's like it).
  The office in the power's colours: the Assembly's Registry Office 14-C with people walking through its middle, the
  Covenant's Chancery of the Return with soldiers at their posts. No flight record, Imre's million, "I'm fired" /
  "I'll be lynched!", nothing carries over. Your licence in the power's design, stamped "APPROVED".
- **What you arrive with:** everything stayed in Beyond but Ossa's suit. A Dragonfly, 30,000 cr, the skill tree back
  at its trunk (pilot level and skills stay), a small room of your own at your first station, free for good.
- **A little later:** a drink with Rook, who stays and will call. What you plan (mining, pirates, science) decides
  the module in your storage. **The next day:** you wake in your room, the ship computer's hologram hands you the
  open game. Journal: "A New Start".
- **Acquaintances:** a new tab in the Pilot window with the main figures you came to know (Dan, Ossa, Rook, Silas,
  Imre): a short description, what they like, where they are, what you lived through together, their bar game, their
  last word. The relationship is a bar from the middle: gold to the right (Acquaintance, Friend, Best friend), red to
  the left (Wary, Rival, Enemy). The story moves it, also for what happened before; a bar game together counts too.
  After the intro Dan is your best friend, Ossa, Rook and Silas are friends.
- **Furniture on foot, looked over:** seats facing up show their backs with the sitter behind them, sofas face the
  room or each other, sitters sit on their seats (bar stools higher), plants and a few pictures no longer cut off.
- Dr. Imre Halden's look (bald, a grey goatee); a bald head keeps its chosen beard colour.
- Debug: Story tab, "Play package 59" parts 1 to 3 (part 3 for either power), "Acquaintances: meet everyone".

## alpha 0.8.58.7 – 2026-11-21

**Package 58, part 8: the strike on the Red Talon Roost (Luz). Package 58 is complete.**
- **The rendezvous** in Hollow, marked gold: Dan (Kanayama-maru), Ossa (Citadel) and Silas (Stubborn Hope) already
  wait there in a line facing the Roost. Come close and a scene starts: their greetings on the radio, your ship flies
  into the middle of the line, Dan: "Then we go."
- **The warp together:** the final briefing on the radio (Silas, Dan, Ossa, Rook, you: "Let's do it."). The warp is
  timed to the talk: it lasts exactly as long as the calls still to come, so you drop out with "Dropping out in
  three... two...". Should the talk run long after all, the warp slows near its end instead of stopping.
- **The Red Talon Roost:** a station of its own with a boss bar at the top (the radio moves below it) and parts with
  bars of their own: four gun platforms (Maul fitting, they go for the ships, not the drones), two hangars that send
  out fighters in waves while they stand (at most 13 alive at once, 17 once the core is open), the hull and the
  reactor core. Every hit lowers the station's bar. At a quarter the plating blows and the core opens (the last wave
  from all around). Solar storms collapse the parts' shields for 12 s.
- **The allies:** Ossa, Silas and Dan go for the fighters while you take the platforms; Dan's drones heal anyone
  badly hurt and are replaced from the ship's stores; Silas jams the guns from the back; pirate radio (Talon and the
  boss) and the allies' chatter.
- **The end:** a chain reaction, then the great explosion; 5,000 cr. The celebration in Dan's bar (the whiskey,
  Ossa's gift: a Light Combat Suit and a Laser Drone, the lent gear back).
- **The party goes on:** stay, dance, play pool. Leave the bar and a window asks "End the party?"; yes: black, "The
  next day", awake in your room.
- **Special opponents:** from the party on, Ossa (●●●●●) and Dan (●●●○○) play pool at Dan's table. Beat one and they
  go into the new collection category "Special opponents" (portrait, game, a line about them).
- Shot down at the Roost: you wake at Dan's, Dan talks about the Maul; the strike starts again at the rendezvous.
- **Frame rate:** NPC ships far from you (over 250,000 km, out of any fight) are worked every 4th frame; the HUD's
  drone, ally and selection panels update ten times a second. In the Roost fight the physics went from about 15 to
  8.5 ms a frame.
- **Fix:** the core can be targeted (L1 / R1 and "nearest hostile" skip parts that cannot be targeted).
- Debug: F12 → Story → "Play package 58, part 8".

## alpha 0.8.58.6 – 2026-11-20

**Package 58, part 7: the relay station (Luz).**
- **The relay** stands on a cold world in Hollow, marked on the map (the gold marker now finds planets and moons too).
  Silas marks it, Rook comes along in the ground team; land the drone far to the south of it, among the rocks.
- **The landing:** the drone comes down, you stay inside. Rook: "Wait. Stay inside, I'll handle this." Two guards
  come round the drone to the ramp; Rook walks down ("Don't shoot the delivery"), talks them into signing for power
  cells the boss never ordered, and puts both down with a shock baton. Then you come out.
- **The compound:** radio masts, domes, a fenced block. Loud: the gate under a turret (its terminal opens the gate or
  switches the turrets off). Quiet: a welded maintenance hatch on the east side (the cutting torch). Inside, two
  levels with cameras, tripwires and **air shafts** (cut the grille, crawl past the guards).
- **The relay room** at the bottom: a great wall of computers with the pirates' routes on its screen. Hack the
  **data core** first (the coordinates of their base), then **overload the transmitter**: lightning jumps across the
  wall, the alarm goes, a 45 s countdown, more of them on the stairs and outside. Back to the drone and up: 2,500 cr,
  Dan on the radio, on to "The strike" (part 8).
- **Fallen on foot:** Rook drags you back, you wake at Dan's with the lent gear kept; the relay starts fresh.
- **Turrets** can be locked (R) and shot to pieces. **Tripwires** warn you when you come close (sneak over, or disarm
  with E from a little further off); one set off is heard nearby but rings no alarm. A terminal hacked once stays
  open (no new E-Breach); Ossa lends five E-Breaches.
- **Fixes:** the sneak round of the simulation no longer restarts at once (the guards see your team only in their
  cone; the round starts low); Rook no longer waits by the lift after the training; the hacking grid works with the
  stick and ✕ (a step the moment you push); a grenade with the controller lands where the stick aimed it; the quest
  tracker on foot sits bottom left (no longer over the team); no "Go in" window at a story's place.
- Debug: F12 → Story → "Play package 58, part 7".

## alpha 0.8.58.5 – 2026-11-20

**Package 58, part 6: the preparation (Luz).**
- **The Listener's end:** "HAH! Got you!" – then Silas finds the readings far too clean and sends you back to Dan.
- **Back at Dan's:** Ossa and Silas wait at the pool table; Dan by the window asks what you want ("About the pirate
  base..."). Black, then the **briefing round the pool table** in the empty bar, without the dialogue's dimming:
  Silas walks round the table, Dan walks up and misses (then says so), Ossa takes the cue and pots the black ("I win
  again"). The pirates talk through a relay station on the ground; Dan, Ossa and Silas will fly against the base
  together once you have its coordinates.
- **Ossa's ground gear, lent:** a Light Combat Suit A, a laser rifle and a pistol, frag and smoke grenades, the
  cutting torch, E-Breach spikes, medkits, energy cells, a laser drone, a shield and a temperature regulator (your own
  gear kept for later). A **guided tour over the Gear page** (suit, protection, weapons, grenades, belt, drone, the
  ground team: take Rook along, the orders).
- **Rook's combat simulation in Dan's hangar** (talk to Rook by the lift): a room of hard-light cover and hologram
  foes. Round 1 a fight (locking on, cover, dodging, the drone, the team wheel); round 2 sneaking (back to the marker
  on the west side, three guards who don't know you're there, their cones of sight, to the east side unseen); then
  three more at a time as often as you like. Shot down: that part again, nobody dies, no loot.
- **Rook Varga** has a look of their own (neon pink sidecut, a scar across the eye, a cyber eye) and knows you.
- **Controls:** the keys in explanations follow the device in use (a foot action explained in a window shows its
  controller button too; a call on screen changes when you switch); the ground team's wheel works with either stick
  and you stand while it's open; the planet map jumps to "Land at …" once a place is picked; a weapon switched on
  while the lock is still coming is armed and fires when it completes.
- **Texts without gender** (Luz): no he/she for people in the story's texts (also in the guidelines).
- Debug: F12 → Story → "Play package 58, part 6".

## alpha 0.8.58.4 – 2026-11-20

**Package 58, part 5: Silas Marr and the Listener (Luz).**
- **Silas Marr**, Dan's old friend, waits in the diner of the Driftwood Waystation. His Bastion, the **Stubborn Hope**,
  undocks and waits 10 s (or sets off at once when you follow her), then warps to a quiet asteroid field. The field is
  cleared of traffic and pirates while he is out there.
- Out of the warp she flies on a little, stops, and Silas calls ("a good spot"); the bar shows **"powering up, starts
  in 5 s"** while the **Listener** unfolds (antenna arms, a turning dish, light arcs, pulses across the field).
- **Three waves** of pirates come for her, each with **one Maul** and light pirates (one, then two, then two). The
  Hope doesn't fight (no guns, no drones). The sweep runs only while you stay near; badly hit, Silas pulls out and you
  meet him at the waystation again. Done: 3,000 cr, the pirates' base lies in Hollow. The Hope warps off home.
- **Fixes:** a beam weapon's shot (its looping sound played once) no longer hums on forever; drones changing role no
  longer crash on a target from the old role; the run-down paint shows on approach, takeoff and the city hatch too;
  Ossa is found in Upper Brine's street after loading a landed save; the story debug buttons in their own tab
  (F12 → Story).
- Steckbrief for parts 6 to 8 (the preparation, the relay on the ground, the strike) written.

## alpha 0.8.58.3 – 2026-11-19

**Package 58, parts 3 and 4: Ossa Kell, the escort, the quarters, three months later (Luz).**
- **Part 3:** after the scrap Dan gives you a free room upstairs (sleep there once), then the job in his bar: Ossa Kell
  of Kell Freight meets you at your ship in **Upper Brine** (Brine's city, now always this name). Her two haulers go
  from Dan's store to the new **Driftwood Waystation** as a real escort contract (3,000 cr), pulled out of warp once
  by two pirates (Ossa and Dan on the radio). Dan lends better gear (a laser A, two armour plates A). Docked in
  Driftwood: paid, then Dan's radio call.
- **Part 4:** docked at Dan's, black and the pilot's thoughts ("Three months later"), a party in Dan's bar (people
  dancing, his toast for you in speech bubbles, cheers), then the two of you on the bar stools talking about the
  pirates (the camera close); you wake in your room. **"Taking the Fight to Them"**: Ossa in Upper Brine's shopping
  street gives you her **Maul**, very well fitted (shield, five guns, armour repairer, drones), in a new run-down
  orange paint, with **Rook Varga** (gunner A, Old Hand) and a guided tour of the crew window.
- **The quarters (new):** a level by the lift on stations and in cities: the lift room, a lobby with the concierge,
  a corridor of numbered rooms (small, medium, luxury; a penthouse lift for later). Closed rooms hide behind their
  doors; one is being cleaned by a robot; your room's door slides open as you come. Renting at the desk, a locker
  with your gear, a night in the bed: the pilot shown lying in it, the planets of the system elsewhere, new contracts
  and bar faces. The pilot is shown as themselves in every bed (also the clinic bed of the intro).
- **Shot down while working for Dan:** no game over, you wake in Dan's clinic; an escort starts again on undocking.
- **Controls:** the camera moved off the ship marks the screen's middle; L1 / R1 then pick by nearness to it, from at
  least 5,000 km, stations, gates and descent beacons too.
- **Cities:** the stairs to your ship open the city's window; "Undock" asks: orbit or the planet map.
- **Radio calls** that only point the way are said once (explanations and tasks stay); ships warping along with you
  are drawn moving again; a deferred mission start no longer restarts a running mission.
- Roadmap: translation planned as package 71b in part 9; story mission rules in the guidelines (4a).

## alpha 0.8.58.2 – 2026-11-18

**Package 58, part 2: the wreck field and the drone's controls (Luz).**
- **Working for Dan in the journal at once:** the deal taken, the story mission "Working for Dan" starts with its
  first point "board the ship Dan gives you". The journal shows only the steps you know (no spoilers of what comes).
- **Drone gear:** Little Darling's drone hangar comes with a laser, a mining laser and a shield upgrade (Dan's, lent).
- **To the wreck field:** Dan marks the wreck field nearest his station. It glows gold in the overview ("◆ objective"),
  the marker on screen points at it, and out of the dock Dan shows how to warp (the overview, picking it, Warp to).
- **The drone's controls:** in the field a guided tour over the drone panel (launch, its jobs, mining, how it works,
  fuel and recall); then twenty units of scrap with the mining laser and the drone; home to Dan: the scrap handed
  over, 2,000 cr and his dialogue. Part 3 (the contact on Brine and the escort) comes next.
- **Drone wheel on the controller:** in space ◯ tapped still deselects; ◯ held opens a ring with Launch, Recall,
  Combat, Mining, Repair and the ways of the current job (the job and its way now marked in gold); the stick picks,
  letting go does it, ✕ cancels. The controller's wheels grow with big screens.
- **No crew yet:** in the story the bars have nobody for hire until the story opens crew (a game without the story
  is not held back).

## alpha 0.8.58.1 – 2026-11-18

**Package 58, part 1: working for Dan begins (Luz).** Package 56 (the intro) is complete; this is the second part
of sequence 6.
- **Little Darling:** Dan's deal taken, he gives you the smallest KHI ship, a Mogura in his rust colours: every core
  module at quality B, a drone hangar and the strongest shield that fits. His gear is lent: it works without the
  skill tree while it stays fitted. The tree's tiles for her, her lasers and drones open; the Dragonfly of the start
  goes (you came out of the Veil with nothing). The lift: "Hangar: Little Darling". Ships can now carry their own
  paint (saved).
- **The guided tour (new):** boarding her opens the station window and Dan explains it: the part explained framed in
  gold and pulsing, the rest dimmed, a tag "3 / 7 • YOUR SHIP"; his radio call stays in front of the window until
  you confirm (a click, E, Space, Enter or ✕; the first press shows all of the call). Meanwhile the menus are locked.
  A task lets clicks through to the framed part only; the window's menu takes the keys and the controller again,
  the highlight kept inside the frame; leaving stays locked.
- **The steps:** the station window in six parts, "open the Outfitter", the Outfitter in four parts, fitting the
  mining laser and the pulse laser Dan left in storage, back to the station window, 2,500 cr advance, the Drone Bay,
  a drone bought; 1,000 cr. The mission "Little Darling" waits at "Salvage" (part 2).
- **Radio calls:** a call can stay until something is done (a flag, its step, or a condition) and shows what it
  waits for; it goes the moment that is done, or when the next call comes. Calls show over every window, at the
  bottom while a station window is open (or wherever they cover nothing being explained), and grow with big screens.
- **Escort missions:** the lead pilot of a convoy you escort calls you over the radio when it is attacked (at the
  gate, pulled out of warp, under fire).
- **Outfitter:** what lies in your storage here shows below what can be bought, in every view (also inside a kind
  of module), in green: no cost, pick and fit.

## alpha 0.8.56.10 – 2026-11-18

**Station windows, part 5: Drone Bay, Repair Bay / Fuel Depot and Munitions Depot (Luz).** With it every station
window on the list is reworked.
- **Drone Bay:** the drone on top with all its values, buying with a slider, repairing the hulls; every stored drone
  as a tile with its fuel and hull and its worth (a click picks it to sell); up to three free places dashed, then
  "+ n more free places"; a clear note when the ship has no drone hangar.
- **Repair Bay / Fuel Depot:** one layout for both: the picked ship big with thick bars (armour and structure, or
  fuel), what is missing, the price and one button "Repair fully" / "Refuel fully"; every ship in the hangar as a
  tile with its bars and cost, and "… all".
- **Munitions Depot:** your launchers, the economy and the hold on top; the mines as tiles ("fits ✓", grey when not
  stocked); the picked one with what it does, its price, what you carry, buying and selling back with a slider.

## alpha 0.8.56.9 – 2026-11-18

**Station windows, part 4: Bond Office and Image Studio follow the screen size (Luz).**
- **Bond Office:** as many wanted posters in a row as fit, each 230 to 300 wide, the writing and the mugshot growing
  with them (three a row at 1280, four from 1600). Your record and the bonds to redeem now come first, the posters
  below. The note on top wraps on small screens.
- **Image Studio:** no fixed width of 1,080 any more; the portrait and the hologram follow the screen's height; the
  three columns stay together in the middle and the gaps grow on wide screens.

## alpha 0.8.56.8 – 2026-11-18

**Station windows, part 3: Refinery and Manufacturing, and production takes time (Luz).**
- **Production times:** a station's refinery works as fast as the Kanayama-maru's (3 units of ore a second for an
  average good); dearer refined goods take longer, aboard ships too. Station fabricators are 25 % faster than a
  ship's factory; components take longer the dearer they are. Every station has a queue for its refinery and one for
  its fabricators: one job at a time, the rest wait (modules no longer all run at once). Refined goods and
  components wait at the station and are collected into the hold there; modules still go into station storage.
- **Refinery:** tabs Refine and In production. The refinery's yields as bars and the cargo hold on top; your ore as
  tiles on the left; on the right the picked kind (ore → refined goods), yield, time, fee, its worth here, "Refine
  all" and "Refine everything"; a note instead of an empty page when the hold has no ore.
- **Manufacturing:** tabs Components, Modules and In production; recipes as tiles (green "ready ×n" when the hold
  has the materials, grey "missing"); on the right the materials as bars, fee, time, "Make 1 / Make all" or "Build";
  the modules chosen by kind in a drop-down.
- **In production:** the job running now, big, with its progress and time left; the queue with when each is done;
  what is ready to collect, per job or all at once. It follows the clock.

## alpha 0.8.56.7 – 2026-11-18

**Station windows, part 2: the Market (Luz).**
- One line on top: the economy and its level, how many goods are made and wanted here, your standing, the cargo hold
  as a bar.
- The filters in one row: Local trade, In hold, All; the category and the economy ("Made by") as drop-downs instead of
  25 buttons. Q / E still steps through all of them.
- On the left the goods as a list (category headings, "made here" green, "wanted" gold, stock, both prices, what you
  carry, m³ per unit); a click or W / S picks one.
- On the right the picked good: both prices, its stock with a bar, what you carry, the best price nearby (Market
  Insider), and buying and selling with a slider and a number (the total shown as you go) instead of +1 / +10 / +100.
  "Max" buys what the stock, your credits and the free space allow; "All" sells everything.

## alpha 0.8.56.6 – 2026-11-18

**Station windows, part 1: the window fits the screen; Shipyard and Hangar rebuilt (Luz).** Before sequence 6, part 2
the old station windows get reworked, one at a time.
- **The window:** never wider than the screen; its margins follow the screen size, lines too long wrap, the station's
  name gives way first (the buttons stay whole). Fixed: after the shipyard (a long hull description) every window
  stayed too wide and "Close" slid off the screen. The Bar shows one column of cards on small screens, Manufacturing
  wraps its materials. Checked at 1280×720, 1600×900 and 1920×1080.
- **Shipyard:** on top the picked ship, a big picture on the left (maker, size), on the right its name and crest,
  class, description, eight values with the standard fit, slots, what it needs (standing, skill tree), the price and
  the two buy buttons. Below filters by size and role and a strip of small tiles, browsed with Q / E, the arrows or a
  click; locked ships show a lock.
- **Hangar:** the same layout: the picked ship with bars for armour, structure, fuel and cargo, its values and fitted
  modules, rename, board, "Fit it at the Outfitter"; the strip shows the ships here first, then those elsewhere
  (greyed, with where they stand). The Citadel's launch platform stays below.

## alpha 0.8.56.5 – 2026-11-18

**Answers said out loud (Luz).** In the main story nearly every answer you pick is now followed by your character
saying it at length: every answer in Dan's talks (his menu, the deal) and to the medic. New guideline in
Leitlinien.md: main-story answers get a spoken version, written to fit when none is given; side missions need not.

## alpha 0.8.56.4 – 2026-11-17

**Package 56, part 4: sequence 6, part 1 (Dan's deal), the journal reworked, and far fewer dashes (Luz).**
- **Sequence 6, Dan's deal:** after the flight training (or straight after sequence 4 if you skip it) Dan waits at the
  bar's window. His menu has a gold answer, "You wanted to talk to me.", which ends the prologue and starts the story
  mission "A Ticket to the Cluster": no ship, no licence, stuck in Beyond ("Stuck?" and "Pilot licence?" in either
  order, then "And what do you suggest?"); a friend of Dan's could take you to the Cluster, for a price; Dan's deal is a
  ship, gear and a few jobs, about three years of them. Yes or no; then black, and the bar is busy again (nobody for
  hire). Said no: three regulars (Hob Karst, Mira Teague, Ossen Vale) turn you down when asked for work, and Dan's menu
  has "About your deal: I've thought it over." (gold). Said yes: a small ship waits in the hangar (part 2 comes next).
  Skipping the training, Dan now answers "Confident, are we? …" and asks you to come over when you're ready.
- **The prologue in the journal:** "Talk to Dan in the bar", the hangar, the training and "Talk to Dan" are steps of
  the story mission "Prologue"; one mission can start the next.
- **Journal:** a new tab "Completed" lists finished missions, latest first, with their full log; Story and Side
  missions show only running ones. Transactions (bounties, contracts, bonds) moved from the ship menu into the
  journal; the ship menu keeps Info, Modules, Ship, Inventory, Industry and Market.
- **Dialogues:** answers can depend on story flags and be shown in gold.
- **Texts:** about 90 % of the dashes (–) in game texts are gone, replaced by commas, colons, periods or parentheses
  (dialogues, radio calls, missions, tips, logs, the codex, descriptions, signs). Titles, ranges such as 1–8 and the
  empty-value mark keep theirs. New guideline in Leitlinien.md.
- **Roadmap:** the Teil 8 table is whole again (a blank line had split it after package 57).

## alpha 0.8.56.3 – 2026-11-17

**Package 56, part 3 – sequence 5: the flight training (Luz).** Chosen in the bar, it is flown with one of Dan's drones.
- **Dan's station before it:** Dan's two lines in the bar (drones; come to the hangar – have a drink, a round of pool);
  Dan at the bar's window, to be asked a few things (the store, Beyond, your ship, where to go, pool); the lift to the
  bar and the hangar; Old Betty in the bay, "Start the flight training?" at her stairs. The medic answers your thanks
  and can be asked again. Nobody for hire in the story's bar.
- **Out:** you ride in Old Betty as in your own ship – the camera, the radar, your icon, the warp tunnel and its sound;
  she aligns and warps to the nearest wreck field; the drone rolls down her flight deck like her own drones.
- **The drone:** Dan's rust-brown remote drone (new art, a hazard stripe, a shield, two lasers, a mining laser, about
  600 km/s, sturdier than a drone); your own ship waits in Dan's hangar meanwhile.
- **The lessons** (story mission "Flight training", every lesson kept in the journal; Dan's radio calls name the keys
  or the controller's buttons, whichever is in use): the journal, a lap round Betty, zoom and the views (one view after
  the other, Dan says what each is for), the fire groups, mining the marked scrap, unloading at Betty, a load from a
  colossus further out. Warp and the gates locked; too far from Betty – a warning, then the drone is lost and a new one
  comes out. No pirates of their own meanwhile.
- **The ambush:** in the Combat view the camera swings to two pirates coming out from behind the colossus; lock, fire,
  drive them off – at first they barely hurt you. One down: the other runs. The drone shot down: the camera back to
  Betty, the pirates leave. Dan explains the pirates, "Let's pack up" – black, back in the hangar; Dan wants a word in
  the bar – speaking to him there begins sequence 6 (with the next part).
- **Dialogues:** no "(go on)" any more – a line without answers goes on with ✕, a click, E or Space; the soft typing tick
  while someone speaks.
- **New game:** no credits at the start; the name preset is "Spacefarer".
- **Controller:** while the window wheel or a menu is open the stick sets no new course (and only again once let go);
  orders given before fly on.
- **Hull alarm:** much quieter, and only in a fight.
- The gold marker also shows a mission step's own target. Saved in the middle of the flight, it starts again at Betty's
  stairs. Debug (F12 → World → Intro): play sequence 5. Smoke group `intro56e` (also in the full run).

## alpha 0.8.56.2 – 2026-11-17

**Package 56, part 2 – sequence 4: Dan's station (Luz).** After the med-scanner the game begins in Beyond, docked at
Dan's Dusty Duty Store.
- **The infirmary:** white; the pilot asleep in a bed (their own skin and hair), Dan and the medic beside it – the
  medic can't make sense of the readings. "A few weeks later": the pilot wakes, Dan introduces himself (Dan T. Rogue)
  and asks them to the bar. "A few days later": on their feet, the medic lets them go.
- **The walk:** the lift shows every level but only the bar can be chosen (the rest greyed out); Dan's station has a
  deck of its own – rust brown, an orange light, the dive bar with its pool table – empty; Dan at the window.
- **The talk:** lines can change speaker within a conversation, the pilot's own lines with their own portrait, and
  after an answer the pilot says it at length; who the pilot is, the UN of Earth, the year (12,900 HE); it ends with
  the choice of the flight tutorial (story flag `flight_tutorial`) – sequence 5 or 6 follows with the next part.
- Hold Esc (Options) to skip the scenes in the infirmary (not the talk). Saved in the middle, it starts again at the
  bed.
- **Visage Clinics** in the scanner's style: the face, the new look as a hologram, the options round it, the price.
- Debug (F12 → World → Intro): play sequence 4. Smoke group `intro56d` (also in the full run).

## alpha 0.8.56.1 – 2026-11-17

**Package 56, part 1 – the intro begins; the game's new name (Luz).** The game is now called **Spacefarer: Beyond
the Veil** (until now Sternenfront) – the main menu, the window, the loading screen, the help, the docs; saves and
settings were copied to the new user folder.
- **New Game starts with the story.** Sequence 1 – the memory: black, the narrator's box; Earth fades in (drawn with
  her real continents, clouds and the lights of her cities); the giant ships of the Expansion leave her with their
  small craft around them (the Gold Fleet as it was: whole, white and gold); the Long Gate; the jump; the Veil creeps
  in from the edges until it has eaten the picture, the Mayday; white-out.
- **The title card:** out of the white into the dark, the Veil spreading from the middle, then SPACEFARER – Beyond the
  Veil; it waits for a key ("Press any button to continue").
- **Sequence 2 – Beyond:** the camera pans through a wreck field (the Gold Fleet's giants behind, wreck colossi,
  scrap); a violet portal, then the Earthworks 190SL – burning, spinning; the pilot's Mayday; the ship's computer (a
  hologram – always when the ship's computer speaks); black; Dan comes in his rust-coloured Kanayama-maru, finds her –
  a life sign on board, life support running out – and tows her away.
- **Sequence 3 – the medic:** ceiling lights pass over in the dark (a stretcher rushed down a corridor), the station's
  medic (Dr. Vesna Kalu – a placeholder name) speaks; white-out; then the **character creator as Dan's medical
  scanner**: the body on the scan bed with a scan line, facial reconstruction, the looks grouped, vitals, identity
  "for the record", the physical and psychological assessment, the galaxy seed small.
- The sequences run on their own timing (lines are not clicked away), a soft typing tick when someone speaks; hold
  Esc (Options) to skip; resizing the window keeps them whole.
- **Looks:** every hairstyle redrawn on foot (front, side, back – light and shade); a new hairstyle, the **sidecut**
  (portrait and figure); **make-up** – lipstick, blush, eye make-up; the eye patch (Dan) also on the figure; the image
  studio shows the figure on foot instead of the old one from above. Dan is an older, broad man with an eye patch.
- **Main menu:** a random scene – an Earth-like world under a G star, a red gas giant before a red supergiant, a
  Directorate ship before a neutron star, a lone black hole; buttons in a sci-fi look.
- Lore: before the Severance "the Veil" was what pilots called the space between the Cluster and Earth (codex).
- Debug (F12 → World → Intro): play sequence 1, 2, 3; open the med-scanner. Smoke group `intro56`.

## alpha 0.8.57.1 – 2026-11-17

**Package 57 – Beyond, a system outside the Cluster (Luz; built before 56, the intro plays there).**
- A pocket in the Veil, well out beyond the Far Reaches: three systems in a triangle – **Beyond** (G star),
  **Driftwood** (K) and **Hollow** (M) – with gates only among the three, none to the Cluster; independent, no pirates,
  no convoys, no notorious captains.
- Beyond: Cinder (lava), Brine (an ocean world with one city), Hush (an ice giant) with its icy moon Rime – round Rime
  **Dan's Dusty Duty Store**, a new, rustic station: long working cranes with big ship wrecks hanging in them, being cut
  up.
- **The Gold Fleet's wrecks, big as planets** (4 in Beyond, 2 in Driftwood): freighters, tankers, arks and escorts,
  freshly torn, half cut up or stripped to the frame – in the sky and on the map like planets.
- **The wreck belt** instead of an asteroid belt (Beyond and Driftwood): on the map gold and rust, plates and pieces of
  ships drifting in it. At least two **Wreck Fields** per system, always metallic (the Gold Fleet's ships were steel):
  - **Wreck colossi** – sections torn off Gold Fleet ships (stern, midsection or bow of a freighter, tanker, ark or
    escort; 12 variants in 3 stages: torn hull, scaffolding and cutting lines of salvage crews, bare frame), 400–1,500
    km, each with a ship's name ("GFS Tithe (midsection)"). They play like the rock colossi: fly round them, radar
    shadow, they block sight, locks and shots, see-through over you; prospect them, mine their steel with a mining
    laser, sometimes deep ore for the Deep Core Drill. The shape you hit is the picture's (torn edges, tanks and modules
    included; the ark's habitat ring and thin radiators are not).
  - **Hull scrap** – the small pieces of these fields (torn plates with seams, ribs, rust and gold trim), mined like
    asteroids.
- The big wreck pictures are made in the background when you arrive; the collision is there at once.
- Debug (F12 → World → Beyond): to Beyond (at Dan's), Driftwood, Hollow; next to a Gold Fleet wreck; next to a wreck
  colossus. Smoke group `beyond57`.

## alpha 0.8.55.1 – 2026-11-16

**Teil 8 begins – package 55: the story's framework (Luz).** What the story will run on (the story itself comes with
packages 56–59).
- The story as data (data/story.gd): missions (story and side missions) of steps, each with goals – dock, get near,
  lock, jump, talk, a story flag – and what happens when a step starts and ends (a dialogue, a radio call, a tip, a
  flag, credits, a secret, a target picked); characters with portraits, dialogues whose answers set story flags,
  tips, secrets. Kept in the save.
- A dialogue pauses the game (portrait, typed lines, answers – keys 1–9, mouse or controller); a radio call comes in
  flight at the top, typed, the game goes on, one after the other; a tip over the module bar ("Got it", "No more
  tips"; keys and controller buttons named in its text).
- The tracked mission's next goals: in space over the ship's panel, on foot under the suit's bars; in space a gold
  diamond on the target with its distance, an arrow at the edge when it is off the screen.
- The journal (Pilot window → Journal, key O; in the controller's window wheel): Story, Side missions, Tips, Secrets;
  missions as long tiles, on the right the mission picked – its steps and goals, what was said (with portraits),
  track it or stop tracking.
- Dan T. Rogue (Luz) speaks for the first time – in the test mission from the debug menu (Missions → Story): a
  dialogue, a radio call and a tip, a station marked (get within 4,000 km), dock there, credits and a test secret.

## alpha 0.7.80.1 – 2026-11-16

**Package 80 – full controller support (Luz).** PlayStation (DualSense) and Xbox, by USB or Bluetooth; the glyphs
follow the controller you hold (and the keys come back with the keyboard); the mouse hides while you play with it.
- Flight: the left stick flies (half way – half speed), the right stick moves the camera; R2 thrust, L1 / R1 next
  target / next hostile, △ lock, ◯ deselect, D-pad ↑↓ zoom; the fire groups: ← held + L1/R1/L2/R2 = 1–4, → held =
  5–8 (shown over the bar while held); □ held: the action wheel (approach, follow, orbit, warp, dock / jump, drones,
  wingmen); Options: tap pause, hold the window wheel (ship, pilot, galaxy map, station, help) – on foot too;
  Touchpad: the list on the right. Prompts along the bottom.
- Orbit and System are maps now: the ship does not fly there (keys too) – the stick (or W A S D) picks the next
  object that way, the camera glides to it, a gold frame round it and the same row marked in the list; ✕ goes there.
- On foot: walk with the stick (all the way: run), flick the right stick at a foe to lock it, ✕ use (hold: revive),
  ◯ dodge, □ the other weapon, △ the team, L1 tactics, R1 next target, R2 grenade (the right stick aims), L2 the
  drone, □ held + L2 the second drone, L3 sneak, D-pad the belt, Touchpad zoom.
- Menus: D-pad or left stick, L1 / R1 tabs, ✕ confirm, ◯ back, right stick scrolls – now every window: the main
  menu, the character creator, the planet map, the galaxy map (stick picks a system, ✕ sets the course), every
  menu on foot (lifts, the Senate, the Curia, souvenirs …), talks and the crew at the bar, the gear shop's tiles.
  The highlight stays in its row or column first and comes back to its place after a page is rebuilt.
- The bar games: billiards (left stick aims, D-pad nudges, right stick spin, L2 held charges – letting go shoots),
  darts (stick aims, L1 holds the breath, L2 throws), Rock Hopper (stick steers, R2 thrust, ✕ drill, □ beam), Drift
  (D-pad, ✕ drift, □ hold, △ warp, ← → the card); the lobby by the menus' rules, △ starts.
- Settings → Controller: on / off, glyphs (automatic, PlayStation, Xbox), dead zones, camera speed, flick, trigger
  point, grenade and billiards/darts aim speed, invert, run by the stick, vibration and strength, every button
  rebindable per context (also D-pad combinations), back to the defaults. Kept in user://controller.cfg.
- Billiards: the aim line takes the cushion as the physics does (the ball leaves flatter; side spin bends it) and
  shows one bank only; hard shots computed in finer steps (the contact point right); the 9-ball rack had two 1s and
  no 4; the guests with 4 and 5 stars aim into the pocket's mouth, hit harder and pick the easiest pot.
- Vibration on hits and explosions. The DualSense extras (adaptive triggers, haptics, lightbar, gyro) come in Teil 9
  (package 71a).

## alpha 0.7.79.1 – 2026-11-16

**Package 79 – fire groups (Luz).** The first part of the new combat controls in space, made to carry over to a
controller later.
- Ship → Modules → **Fire groups**, a new tab: every module you switch on in a fight, with the fire groups 1–8 it is in
  – a module may be in several. Left: what is in which group with its key, "Assign by kind" and "Clear all groups".
- Until you change them, the groups follow the kind: each kind of weapon its own group 1–3, the auto mode 4, tools 5,
  active modules 6, point defence and mines 7. Kept per ship in the save.
- The module bar shows one tile per fire group (its key, the first module's icon, "Railgun ×2", the cycle, T1/T2);
  modules in no group are not on it.
- Keys 1–8 switch a whole group: any module of it off (or on another target) – all on at the active target; else all
  off. An empty group says where to set it. Key 9 is free.

## alpha 0.7.54.18 – 2026-11-16

**Review of Teil 7 – all findings fixed** (report `reviews/teil7_review.md`, made with Fable 5.2).
- W1: what happened at a site to explore is kept – opened crates and doors, cages, vents, drained tunnels, the fallen,
  the minimap – when you change level, take off and land again, go from the alley to the roof and back, or save and
  load; it goes with the site (its target done, or the next visit to the system). No more loot over and over.
- W2: fuses, tripwires and timers (lock picking, cranked doors, the vault drill) stay with their level and run on when
  you come back – no script errors every frame, nothing hanging half done.
- M1: a new game starts with an empty Museum, no photos, no streaks, no sites done.
- M2: the Archivist Suit is never lost – pockets full, it goes into the ship's locker, else the curator keeps it for you.
- M3: the corporate tower's key card stays taken when you leave the Roof Plaza.
- M4: sneaking – the foes' view cones are cast again only when they move or turn, and not off the screen.
- K1: keys held do not carry over into the next level; E does nothing while the platform sinks.
- K2: a team member down dies when you take off, as when you change level.
- K3: an abandoned reactor job no longer leaves the city's tunnels dark.
- K4: the planet map shows the cloud cities' weather (gas winds, gas storms).
- K5: the souvenir stall says how many you really bought.
- K6: an audience with the Hierarch no longer overturns a petition the Curia has heard.
- K7: a street's ads and a landing's walkers no longer change each visit.

## alpha 0.7.54.17 – 2026-11-16

**Package 54e – dynamic weather (Luz).** Weather for everything out in the open – city streets and plazas,
settlements, the outside of sites, the wild, sights, a cloud city's deck. Only to look at for now: nothing changes what
you see of foes, your suit or sneaking.
- Each region of a world has its own weather, a spell of about six minutes of play that sets in and clears slowly;
  places close together share it. What can come depends on the world: rain, thunderstorms, fog and overcast on green
  worlds, snow and blizzards on ice, dust and sandstorms with dust devils in the desert, ash with rising embers on lava
  worlds – none where there is no air.
- The cloud cities get the giant's own gas: gas winds, and in a gas storm long torn veils in the giant's colours racing
  across the deck, lightning lighting the clouds from within, thunder after it.
- The light dims and tints, haze drifts with the wind, rain splashes on the ground; a bolt flashes over the street.
- People put up holo umbrellas when it rains or storms – a dome of cyan light, the rain bouncing off it (not the
  guards, not you).
- The planet map hints at it: cloud fields over the places where it rains or snows, a storm's spiral turning, an icon
  beside every place (a sun, at night the moon) and the weather there in the place's info.
- Placeholder sounds: rain, wind, thunder. Debug menu: "Weather (package 54e)" – force any weather, back to the world's
  own, lightning now.

## alpha 0.7.54.16 – 2026-11-16

**Package 54c, part 7 – the galleries at the capitals' yards (Luz).** A level of its own in the lifts of Concord Yards,
the Forge of Return and the Axiom Yards – the last of the special stations' rooms: package 54c done.
- A long window onto the dock with the great work in it, drawn with its own art as it lies out there – the Res
  Publica, the Lux Aeterna, three jump gates being built – gantries with work lights in front, welding sparks, drones.
- The gallery in the power's colours: benches looking out, a model, information, a souvenir stall (Shipyard Rivet), the
  power's guard (the Senate's, the Hierarch's).
- A sight in each: events – the yard at work, a hull segment moved in on a tug (seen), a test of her drives (seen), a
  change of shift, a probe jumping through a new gate (rare, seen). Excursion targets in all three capitals.
- Debug: F12 → Ground → Capitals → Yard galleries. Smoke test group `yards54c`.

## alpha 0.7.54.15 – 2026-11-16

**Package 54c, part 6 – the Meridian Sphere's control room (Luz).** A level of its own in the Meridian Sphere's lift.
- The window front of filter glass: the star of Durchbruch in its own colour (an A star – white-blue), its granules and
  a prominence; the shell's frame rings with the honeycomb of collectors; construction ships working along the rings,
  a collector held on an arm, welding sparks; drones.
- Three tiers of consoles facing the window, technicians at them on stools; the sphere's holo; the Research Exchange
  on foot (data, exotic matter – as at the station's window).
- A sight: the viewpoint at the window, information, a souvenir stall (Collector Cell Keyring); events – collectors
  going in, a new field (more ships), a solar storm (the prominence great), a change of shift, a flare (rare: the
  glass darkening). An excursion target.
- Debug: F12 → Ground → Capitals → Meridian Sphere. Smoke test group `control54c`.

## alpha 0.7.54.14 – 2026-11-16

**Package 54c, part 5 – the Cathedral's nave (Luz).** A level of its own in the Cathedral of Return's lift.
- The great pointed window onto space with the Pilgrim Gate in it exactly as it stands out there (its own art: the
  ring, the twelve spires, the stained bands, the lights), its beam reaching out towards home, the stars twinkling.
- The altar on its steps, candelabra, lancets, banners; the nave with its runner, pews, columns, censers, the windows'
  colours on the floor, pilgrims; the Curia on foot – the chancery (edict, tithe, petition, indulgence) and the relic
  shrine; the Hierarch's guard in gold.
- A sight: the viewpoint before the altar, information at a lectern, a souvenir stall (Pilgrim's Candle); events – a
  mass, the choir, a pilgrim ship jumping through the gate (seen), new pilgrims, the gate's light falling (rare, seen).
  An excursion target.
- Debug: F12 → Ground → Capitals → Cathedral of Return. Smoke test group `nave54c`.

## alpha 0.7.54.13 – 2026-11-16

**Package 54c, part 4 – The Vote's gallery (Luz).** The first of the special stations' own rooms: a level of its own in
The Vote's lift, the gallery over the drone shaft.
- The shaft going down through the station's heart (its wall darkening into the depth, the frame's ribs, the decks'
  lit windows), the blue beam rising, ballot drones spiralling up to the ports – and every few seconds a big one passing
  close by the window; the tally as a holo over the shaft, live (the bill, yes and no, the systems reporting).
- A strip of glass floor at the gallery's edge (the shaft below it), the railing, three voting booths of frosted glass
  (your vote on the bill, as at the Senate's stand), the Assembly's guard.
- A sight: the viewpoint at the railing, information, a souvenir stall (Ballot Drone Model); events – the drones
  streaming, a vote closing with a swarm (seen), the beam flaring (seen), a quiet hour, every system at once (rare).
  An excursion target.
- Debug: F12 → Ground → Capitals → The Vote. Smoke test group `vote54c`.

## alpha 0.7.54.12 – 2026-11-16

**Package 54c, part 3 – the capitals' sights (Luz).** The capitals' own places are now sights for tourists, and Curie
has the Mirror Front (the Founders' Terrace and the Pilgrims' Ridge are dropped – the plazas take their place).
- **The Plaza of the Vote** (Neo Kallipolis) and **the Palace of the Hierarch** (Aureola): a viewpoint for photos (at the
  foot of the Senate's stair, before the palace's stair), information, a souvenir stall (Glass Senate, Sun of Return
  Pendant); events by visit and hour – the session letting out, a demonstration, the flag lowered, the front lit at
  night, a drone show of the founders (rare; seen); the changing of the guard, pilgrims on the mosaic, the star going
  down red, a vigil of candles (seen), the Hierarch's procession (rare). Both are excursion targets.
- **The Mirror Front** on Curie (Durchbruch): a terrace on the ridge where the new fields meet the old desert – the
  parcels, tracks and shining channels, the churned line with the Institute's towers, the orbital mirrors in the sky
  and their beams slanting onto the fields; events: the beams sweeping, seed drones, the towers' long shadows, the
  mirrors crossing the night like slow stars, the first rain (rare). Souvenir: a Mirror Shard. An excursion target.
- Debug: F12 → Ground → Sights → The Mirror Front. Smoke test group `sights54c`.

## alpha 0.7.54.11 – 2026-11-16

**Package 54c, part 2 – Aureola and the Hierarch's palace (Luz).** The first cloud city over Compline (Heimkehr) is now
**Aureola**; its skyrail has a fourth stop there, the palace's own station.
- **The palace station:** built like the line's others, dressed like the palace – warm stone, lancets, banners,
  braziers, saints; through the passage in its wall across the bridge to the palace platform.
- **The palace platform:** a great disc over the red clouds at the one true scale, a gilded balustrade all round its rim
  (its sides too), the warm stone face under it; the palace front 60 m high – near it you see only its foot: the portal
  10 m wide with its bronze leaves, piers with saints in niches, banners from far above, the great stair with cheek
  walls; the sun mosaic, braziers, two pools, the chaplain-admiral, lanterns, benches at the balustrade, pilgrims.
- **The lobby:** the guard in two rows along the runner and at the inner doors; the **Curia's chancery** (the edict on a
  scroll, tithe, petition, indulgence; the queue behind a rope), the **relic office** (relics laid in the shrine, the
  blessing; candles, cases of relics of Earth), Earth on a globe, a lectern with the Book of Return, fonts, censers,
  saints, pews, the sun mosaic, the windows' colours.
- **The throne room:** the great window in the back wall – the star rising over the red clouds of Compline – the sun's
  halo under it; the throne at a man's size, carved and gilded, on a plinth 2 m up under a canopy, the regalia beside
  it, the Hierarch on it in crimson and gold; broad steps, candelabra, statues of the Hierarchs, pews for the court,
  courtiers. Only the **Allied** of the Covenant may step up: below that a rope and the guard bar the way.
- **The audience:** the first time the Hierarch's seal (indulgences at half price, for good); then once each edict name
  the next edict yourself or kneel for his blessing (40 min); he speaks of the Return.
- **The Hierarch's guard:** a new armour for NPCs only – gilded plate, a red crest, a long crimson cape with a gold hem.
- Debug: F12 → Ground → Capitals → Aureola (the station, the platform, the lobby, the throne room, Allied, a new
  edict). Smoke test group `palace54c`.

## alpha 0.7.54.10 – 2026-11-16

**Package 54c, part 1 – Neo Kallipolis and the Senate (Luz).** The capitals get names and hand-built places: the first
city on Agora (Landfall) is now **Neo Kallipolis**; its lift goes up to the Senate of the Assembly.
- **The Plaza of the Vote:** the Senate as a sci-fi front – white composite, a curtain wall of blue glass, glass portal
  doors under the Assembly's seal, banners of light, pylons with a glowing core, a broad lit stair flush with the front
  and closed by cheek walls; on the roof the great faceted glass dome with its ring of light, solar arrays, masts. The
  founders as holograms by the fountain (a bronze plaque on a stone), the civic wings in glass, the bill on a holo.
- **The lobby:** the security arches are the only way in (glass barriers, a rope over the runner, a guard posted at each
  arch, a tone as you pass through); the Assembly's seal in the floor under the bill's holo, a blue runner to the grand
  stair, news screens, holo busts of speakers past, the founding exhibit (Agora, the first colony ship, the charter),
  the information desk, waiting benches, visitors. The **party office** takes donations, the **lobbyist** on his sofa a
  bribe – the same as the Senate window.
- **The gallery** high over the plenary chamber, seen slanting through its glass panes: the hemicycle full of senators,
  a hearing at the witness table, desk lights as votes come in, the great screen changing its picture every few
  seconds with a flash (the witness, the bill and its polls, figures, the seal). The **voting stand** casts your vote;
  the benches face the chamber.
- New art: decals `senate_roof`, `steps_lit`, `senate_seal`; face decos `senate_front`, `senate_doors`, `holo_banner`,
  `light_strip`; objects `pylon`, `holo_statue`, `scanner_gate`, `news_wall`, `plaque_stone`; standing signs. Sound
  `scanner_pass` (placeholder). Debug: F12 → Ground → Capitals. Smoke test group `capital54c`.
- Roadmap: 54c steckbrief agreed (Senate in Neo Kallipolis, the Palace in Aureola over Compline next); 54d (settlement
  trade) moved to Teil 9 as 74a.

## alpha 0.7.54.9 – 2026-11-16

**Package 54b done – tips and sounds (Luz).**
- **Tips:** beat a guest for a stake and now and then (about one win in three) they let something slip – an anomaly
  near by that their scanner caught (it shows on your map now), or a ware that is cheap at a station here and pays well
  within two jumps (real prices of the moment). In the log and on the result panel.
- **Sounds:** the bar games have their own now – the cue's tock, balls clacking, the cushion, a ball dropping into the
  pocket; the dart's whoosh and thud; cards dealt and shuffled; the arcade's coin, drill laser, 8-bit explosions, ore
  picked up and banked (placeholders in `assets/sfx/`, in the sound list).
- Billiards: the aim line goes on off the cushions (up to two banks, fainter each time). Darts: aiming is harder – the
  hand sways about a ring's width even when steady, holding your breath steadies it less and not for as long, and the
  release scatters a little (Luz).
- `tools/audio/make_placeholders.py` can now make only the sounds named (the others, maybe real sounds by now, stay).
- Smoke test group `tips54b`.

## alpha 0.7.54.8 – 2026-11-16

**Package 54b, part 3 – Drift, the card game (Luz).** At a card table in the lounges and the garden bars: you and two
or three guests of the bar (the one you choose in the lobby, others sit down too).
- Cards 1–10 in four suits (comets, moons, suns, nebulae) and four Warp cards worth nothing. Two cards each; in turn
  draw (drift) or hold – over 21 burns out. Closest to 21 takes the pot of everyone's stakes (shared on a tie); hit
  exactly 21 – a Singularity – and you win at once. A Warp swaps one of your cards for the deck's top one.
- The guests' first card lies face down until the showdown; they draw low and hold high (the better ones sooner), and
  warp a low card away. Stakes and win streak as at the other bar games.
- Every move goes through the command bus (`drift_move`). Debug: F12 → Ground → Bar games → Drift. Smoke test group
  `drift54b`. All four bar games of package 54b are in.

## alpha 0.7.54.7 – 2026-11-16

**Package 54b, part 2 – Rock Hopper, the arcade cabinet (Luz).** Two cabinets in the waystations' diners, one by the
pool of the resorts' beach bars – a high score game, 1 credit a game.
- Fly a mining tug through an asteroid field: the drill laser cracks the rocks (big ones split, small ones shatter),
  the ore spills out, the tractor beam pulls it into the hold (6 nuggets). Only ore brought home to the refinery in the
  middle counts – dock there slowly; a full hold counts double, and the tank is filled. Thrust, laser and beam burn
  fuel. Lose a tug (a rock, a shot, an empty tank) and the hold spills; three tugs. From wave 3 pirate drones hunt you
  (+100 each); every wave a bonus, more rocks, faster.
- The cabinet's screen with its glow and scanlines; each cabinet keeps tonight's best – invented regulars and your
  own scores there; your best overall too.
- Debug: F12 → Ground → Bar games → Rock Hopper. Smoke test group `rock54b`.

## alpha 0.7.54.6 – 2026-11-15

**Package 54b, part 1 – bar games: billiards and darts (Luz).** What stands in the bars can be played now.
- **A lobby before every game:** the mode, the seats – you and a guest of the bar (name, trade, strength, a line) or
  one of your crew aboard; a seat for a co-op player is already there for later –, the stake, the rules, start.
- **Stakes by the win streak:** low (up to 200 cr), from 10 wins in a row medium (up to 1000 cr), from 25 high (up to
  5000 cr) – and the guests get better with it; a loss ends the streak; playing for nothing always works.
- **Billiards** at the pool tables of the dives (mining colonies, pirate havens) and now the lounges too: the camera
  down on the table (wooden rails, leather pockets, the lamp on the cloth), real balls – cushions, ball on ball,
  follow, draw and side on the cue ball –, aim with the mouse (the aim line, the ghost ball, where the object ball
  goes), hold for power, the right button for spin. 8-ball (groups, fouls, ball in hand, the 8 too early loses),
  9-ball (lowest ball first, the 9 wins) or practice alone. The guest picks the best open shot and places the ball in
  hand well, more or less accurately by strength, and comments on it.
- **Darts** at a board on its stand in the mess halls and canteens: the camera on the board (sisal, wires, trebles and
  doubles); 301 or 501 down to exactly nothing (below is a bust), or around the clock alone (your best kept). The hand
  sways – less with Reflexes, more after drinks; hold the right button to hold your breath. The guest goes for the
  trebles, then a finish.
- Drinks at the bar make the cue wander and the hand sway.
- Every shot and throw goes through the command bus (for co-op later). Debug: F12 → Ground → Bar games (open a lobby
  anywhere on foot, set the streak, win or lose now). Smoke test groups `minigames54b`, `darts54b`.

## alpha 0.7.54.5 – 2026-11-15

**Package 54a – sights on the ground, excursions and shuttles (Luz).** On most worlds of the right kind the planet map
now shows a **sight** (✦): land, walk from the landing place to its viewing terrace (glass railing, benches to sit on,
viewing scopes, an information holo, a souvenir stall, other sightseers about) and look out.
- **Six sights, one per kind of world, in great detail:** the **Glass Falls** on jungle worlds (a waterfall off a rock
  wall into a pool, the creek running off, giant trees); the **Coral Lagoon** on ocean worlds (a beach with palms, the
  turquoise lagoon in a ring of reef islets, corals and fish under the water, a jetty out to a viewing platform); the
  **Ice Cathedral** on ice worlds and moons (a banded glacier wall, its portal and the nave behind – ice pillars, a
  frozen waterfall glowing at its end –, a frozen lake as clear as glass, seracs, a crevasse with a bridge); the **Red
  Arches** on desert worlds (mesas in the haze, three sandstone arches on the plain, a banded canyon at your feet with
  a dry wash and cottonwoods); the **Fire Terraces** on lava worlds (a smoking volcano, basalt terraces with columns,
  rivers of lava pouring over them, lava lakes, embers, glowing cracks at your feet); the **Great Crater** on barren
  worlds and moons (the far rim against the black sky, the floor with its central peak, a fresh impact with rays, a
  research outpost blinking far out).
- **Worth coming back:** what is to be seen changes by visit and hour – a rainbow or a moonbow in the spray, morning
  mist, fireflies, a herd come to drink; shoals of fish, glowing jellyfish at night, the sun going down over the reef,
  a great sea creature passing; the ice glowing deep blue, an aurora mirrored in the lake, sun dogs, the ice singing;
  the sun setting through the great arch, the stars, a dust devil, a sandstorm wall; fresh lava, the glow at night, a
  lava fountain; the planet rising behind the crater's rim, the star field, long shadows, a meteor shower. The far
  views have a real sky (the sun behind the mesas and through the arch, the planet behind the rim).
- **Photos:** at the railing (E) you take a photo – a travel magazine buys each new one (150 cr, rare views 600 cr);
  the holo tells you which you have. **Souvenirs:** a new ware for each place (Falls Spray Globes, …), sold well far
  away in mining and military systems.
- **The Skyring deck:** the observation deck at the cloud cities' Skyring stop is a sight too – a glory round the
  city's shadow on the clouds, lightning deep in the clouds at night, gold at sunset, moonlight on the cloud tops, sky
  floaters drifting past (rare); souvenir: Bottled Cloud.
- **Excursions:** a new round trip on the passenger board – land with the sightseers at a sight (in this system or up
  to three jumps off; or the Skyring deck), **stepping up to the viewpoint is enough**, then bring them back.
- **Shuttle runs:** passengers from a station down to a city's hangar in the same system, or from a city up to a
  station – short, quick, paid less per head.
- The crystals on the ground are new: six-sided prisms lit from the side, with light inside.
- Debug (F12 → Ground → Sights on the ground): each sight with each of its events and the hour, the Skyring deck's
  events, an excursion or a shuttle run aboard, "excursion seen". Smoke test group `sights54a`.

## alpha 0.7.54.4 – 2026-11-15

**The view from the sky bar (Luz).** Through the bar's glass the city's own towers now stand in front of the clouds in
two rows (the far one in the haze), in its power's style – glass bands, roof gardens and domes, the Covenant's golden
windows and spires, the Directorate's green bands and hexagon crowns, the free city's antennas and neon. Along the
horizon the top of the cloud deck rises in billows, lit on their tops; above it the star, veiled in streaks of thin
cloud – high by day, low and red at dusk (the cloud tops glowing), gone at night, then stars, and the towers' windows
lit. Fix: the bar's window took the hour only late (too bright at night).

## alpha 0.7.54.3 – 2026-11-15

**Package 54 done – the approach, the underdeck, the powers' styles (Luz).**
- **The flight in:** down to a cloud city you sink through the giant's **cloud decks** – lit billows in its colours,
  the nearest passing over the ship – then below them the **city comes into view**: its platforms painted in pixel art
  (paving, a promenade ring, green terraces, the buildings in the power's style with glass bands, roof gardens,
  domes, spires or hexagon crowns, spindles, capsule lift tanks and rotor rings below), the skyrail between them with
  its cars; the main platform grows until its **hangar gate** on the rim (a force field, landing lights) takes the ship
  in. Out again the same way, backwards. **By the hour:** dusk and night darken it and light its windows, light bands,
  neon and running lights.
- **The underdeck:** the lifts go down under the deck – catwalks of grating between lift tanks and antigrav rotors,
  rails over the open clouds below, maintenance drones; calm without a job. A new job **"Rotor restart"**: a lift
  rotor jammed and the city lists – go down to the rotor hall and restart it at its console (weapons allowed).
- **The powers' plazas in detail:** the Covenant's fronts with pointed arches and golden glass, red banners on the
  pillars, lanterns; the Directorate's white with hexagon glass and green light bands in the floor; the free city's
  neon-framed fronts, holo adverts and stalls; the Assembly's as before.
- Debug (F12 → Ground → Cloud cities): "Underdeck – calm / rotor jammed (job)".

## alpha 0.7.54.2 – 2026-11-15

**The gas works and the skyrail (Luz).**
- **The gas works – the skyrail's third stop (Harvester Deck):** the platform at its west end, then the works' deck of
  steel with a yellow walkway – spherical tanks, compressors, a column going up out of the picture, a flare burning
  off what is left, a pipe run with steps over it, the control room's long window, workers in their suits. At its
  edge the winches let the **intakes** down into the clouds, swaying; a **catwalk** with glass railings goes 6 m out
  over the void, a scope at its end looks down at the harvest probes.
- **Gas Exchange:** at the works' counter the giant's own gases (a gas giant's hydrogen, helium and helium-3, an ice
  giant's nitrogen, neon and xenon …) at 30 % under market price – 10, 100 or a full hold, straight into your ship.
- **The berth:** now and then (a new roll every half hour of play) a great **KHI gas freighter** of the Kujira class
  lies there under its own name – its round tanks huge beside the deck, held by clamps, a loading hose down to it;
  otherwise "Berth 1 – free".
- **The skyrail** now asks where to when you board – the line runs between Central, the Skyring and the gas works.
  Aboard you see the car **pull out of the station** (the platform slides away behind) and **pull into the next**
  (it comes in as the car slows; the doors stop right at the gap). The car hangs from two **maglev bogies** on the
  beam – clamped round it, their field coils pulsing along it, a pylon down into the roof; the grab poles inside run
  from the floor to the ceiling.
- Debug (F12 → Ground → Cloud cities): "Gas works" and whether a freighter lies at the berth.

## alpha 0.7.54.1 – 2026-11-15

**Package 54 – cloud cities (Luz).** Every gas giant of an inhabited system has **one or two cities hanging in its
clouds** – the descent beacon now leads to a giant too, and there you go down only to them. What they live on follows
the giant: gas giants trade and harvest gas, ice giants research and cool, red giants refine, the toxic giants have
small sealed outposts. Walked like the cities on the ground, in their own design and at real scale, after Luz'
approved mockups:
- **Hangar** as in the other cities – the gallery with the lifts, your ship down in the hall – its far wall a **gate
  open to the sky**, a force field shimmering in it, the clouds beyond.
- **Plaza with its balcony:** the shops' glass fronts between stone pillars (walked into as everywhere), the lifts in
  the middle, trees in planters, lamps, a café with parasols; along the edge a glass railing and **benches looking out
  over the clouds** (all of them seats, people sit down too); few guards. At its ends a hedge of planters – the
  platform goes on beyond.
- **Skyrail:** the station with its departures board, the yellow line and glass screens; the **suspended car**
  waiting below the edge, its doors on the platform's side. Board it and **ride** – the doors shut, it speeds up, the
  clouds, far platforms and the beam's masts pass by – to the **Skyring** with its observation deck and viewing
  scopes. The car is closed: its roof and side with big windows, you see inside through them; the doors open at the
  stop.
- **Sky bar** (the tower bar) with the giant's sky in its windows.
- **The giant all round:** a **sea of clouds** in the giant's colours under every deck – three layers moving with
  depth, drifting in the wind, a **storm eddy**, **lightning** deep down, other platforms far off in the haze, struts
  and lift tanks hanging under the deck's rim; day and night over it.
- **The air:** thin and cold or poisonous on most giants (suit and helmet out on the deck, the townsfolk in suits
  too), breathable at normal pressure over some gas giants.
- Debug (F12 → Ground → Cloud cities): into a cloud city of any kind of giant and power, its air and hour, any level;
  the skyrail arrives at once, its state.

## alpha 0.7.53.36 – 2026-11-15

**Peaceful animals are not foes (Luz).** R and Shift+R never pick a peaceful animal, and no shot goes at one on its own
– not yours, not your drones', not your team's. Click it to mark it; click it **again** to **hunt** it, then you fire
as at any target. In the tactical view the **view cones** of the foes show **only while you sneak**.

## alpha 0.7.53.35 – 2026-11-12

**Package 53f-2 – the wild (Luz).** Jungle, ocean and ice worlds now have **wild country** to land in, hunt and explore,
after Luz' approved mockups – painted at the ground's real scale, the whole site one great open map:
- **Jungle path:** a rock wall with a **waterfall** in the north (no way up), **thorny thicket** round the other sides;
  the creek from the falls' pool runs across the forest – cross at **fords of stepping stones**; winding paths, sunny
  clearings, giant trees with crowns of many leaves (you walk behind them), ferns, flowers, fallen trunks as cover.
  Beyond the creek an **overgrown site of the Precursors** – on its altar a find for the Museum.
- **Coast and islands:** a chain of islands in the open sea – beaches, wet sand, tide pools, palms, driftwood,
  **boardwalks** and sand bars between them; on the far island a **crashed landing drone in its crater**, still
  smoking – its cargo pod may be whole.
- **Ice field:** an ice cliff with a **cave** (a frost worm's nest, the eggs glowing), open black water with
  **drifting floes**, **pressure ridges** of broken slabs, **crevasses** with bridges, cracks, glare ice, blocks of ice
  as cover.
- **Water that moves:** a shader under the map – waves rolling in, the **surf running up the beach** and back,
  whitecaps far out; the creek and the polar water shimmer. Water and crevasses block the way, not the view.
- **Animals** (Luz' ideas, own designs), all can be attacked: **peaceful** ones graze and wander and **run** – the
  whole herd – when you come close (sneak to get near); **dangerous** ones guard their **ground**: step onto it and
  they come, leave it far enough behind and they let you go; some **lie in wait** hidden (the lurker in the reeds, the
  eel in the sand, the worm under the snow). Jungle: ridgeback grazers, glider lizards, quill hunters in threes, leaf
  lurkers. Coast: shore crabs, armoured crabs, sand lurkers. Ice: snow tufts, frost bears, frost worms. The animals are
  always seen from the side.
- **Loot:** hides, pelts, crab shell, game meat, tissue samples go into your **pockets** (sold at a gear shop); the big
  ones also put **Exotic Hides** and **Wild Game** into your ship's **hold** as cargo.
- **Hunting jobs** on the board ("On foot"): bring down **the old beast** of a kind (marked, red) or **cull** a number
  of them – on a jungle, ocean or ice world near.
- Debug: F12 → Ground → Sites: The wild (jungle, coast, ice); F12 → Missions: Hunt.

## alpha 0.7.53.34 – 2026-11-12

**Package 53f-1 – creatures and machines (Luz).** The places on foot get foes that are not people:
- **Security robots** in the corporate towers – lanky, grey with sand-coloured plates, a red eye, a rail carbine;
  armoured, they never run.
- **Precursor keepers** in the ruins of the Precursors – dark machinery under glossy blue plates; once they have seen
  you the blue turns **red**. A laser rifle and heavy armour.
- **Necrotic husks** of the Dark Ones with the cult in their ruins – black, violet cracks and eyes, **steaming**; they
  strike with their claws, **heal** while you leave them be and **get up once more** after falling.
- **Mutant rats** in the sewers, in **swarms**; **cave crawlers** in the old mines that come out of the cracks;
  **escaped specimens** in the research stations – fast, pale, many-eyed.
- Creatures fight **close up** (claws, teeth – no shot flies, the strike lands in reach). They **join or replace** the
  people of a place. Machines leave **salvaged parts** (credits), creatures **samples** (research data).
- **New job "Rat plague":** under a city the sewers crawl with rats – both levels are sewers now; kill their **brood
  mother** on the lowest level.
- Debug: every creature in the foe list (F12 → Ground → Combat on foot), the rat plague job (F12 → Missions).

## alpha 0.7.53.33 – 2026-11-12

**Drones on the arm (Luz).** Every suit now carries its switched-off drone on the outside of the **right upper arm**,
as the Senate armours do (they keep one on each arm) – no longer on the back.

## alpha 0.7.53.32 – 2026-11-12

**The debug menu tidied up (Luz).** Every tab is now made of **sections that fold open and shut** (▸ / ▾) – shut at
first, what you open stays open while the game runs; **Open all** / **Close all** at the top. The World tab is in a
sensible order (travel, the special systems, the cluster and its bodies, economy and mining, pirates and ships); the
Ground tab's long combat part is split into the arena, foes and the fight, drones and the team, tools, sites to
explore and the Museum.

## alpha 0.7.53.31 – 2026-11-12

**The Archivist Suit gets its own look (Luz).** A graphite undersuit with white accents, a chest rig of grey pouches
on dark straps, one big shoulder plate, a teal pouch at the hip, knee pads and white straps on the boots – under a
hood, a scarf and a slanting wrap of deep green cloth. Its helmet is a round mirrored glass inside the hood, and an
antenna rises from the pack on its back, a red light at its tip.

## alpha 0.7.53.30 – 2026-11-12

**The Museum – the curator takes your finds (Luz).**
- **Hand your finds to the curator:** "I have something for the Museum!" – delighted, the curator tells you about each
  piece in turn (a little more breathless for the rare ones), pays the Museum's thanks and, once you part, walks off
  through the arches and up the stairs to set them into their cases, then comes back to the desk.
- **A filled case** opens a conversation box: the piece's picture where a face would be, its story where the words
  are. An empty case tells what belongs there and where such things are found.
- **"Rewards"** appears in the curator's talk as soon as a room is complete – what each full room gives, and the suit.
- **Benches** by a wall face into the room – you sit with your back to the wall.
- **The roof:** a marble parapet with urns on its corners, two raised marble attics with skylights, and a glass dome
  with relief – lit from one side, its ribs and rings, a drum of columns, a lantern on top, its shadow on the roof; the
  roof lit like the plaza at night.

## alpha 0.7.53.29 – 2026-11-12

**Fix (Luz):** the Museum hall's side rails on the gallery's wings stand on the edge of the raised floor and run down to
the front rail.

## alpha 0.7.53.28 – 2026-11-12

**The Museum – benches, guards, the details (Luz).**
- **Benches you can sit on** – in the Museum and on the roof plaza (E). **People sit down by themselves** now and then
  on a free bench or sofa, stay a while and walk on (everywhere in the game).
- **Two guards at the Museum's doors** – no city guards walking its rooms. Fewer visitors while the cases are empty;
  more the fuller it gets.
- The hall: the **gallery's wings have a rail along their fronts**, the side rails end flush with it; the **signs hang
  lower** on the wall, over the arches.
- The basement's **stairs up** rise into the back wall like the grand stairs, lit from the hall above.

## alpha 0.7.53.27 – 2026-11-12

**The Museum – polish (Luz).**
- **The curator** now talks with you in a real conversation like the bartender, with her portrait: how full the Museum
  is, your finds (sell the spare ones), a hint where to look for what is missing.
- **The curator's desk** shows its marble top from above, the things on it standing on it.
- The upper floors have **openings** in their south wall as the way back down instead of the start of a stair; the
  minerals room leaves the same way.
- The **arches** to the minerals and to the Dark Ones are simply dark.
- The **minerals room** is bigger and has **holograms of mining ships** (Mogura, Iwakudaki, Kujira) on their projectors.

## alpha 0.7.53.26 – 2026-11-12

**The Museum – a room each (Luz).** The hall is built as in the mockup: above it, seen over the rail, the gallery in a
U with the exhibitions' banners; in its middle the **grand stairs up to a gate** – through it the **first floor**, a
room of its own (the Old World west, the Severance east), and there again the grand stairs up to the gate of the
**second floor** (the Precursors). Under the gallery's wings **two arches**: west into the **minerals room** (its own
room now), east the **stairs down** to the Dark Ones. The flights running sideways are gone; stairs down to the floor
below lie at each upper room's south side.

## alpha 0.7.53.25 – 2026-11-12

**Package 53e – the Museum in Curie (Luz).** In the city on Curie (Durchbruch) the lift goes up to a roof plaza with
the **Museum**: an avenue of statues (a pilot, a soldier, a colonist – and a Precursor), a white front with columns,
a glass dome over the hall, the doors open.
- **48 exhibits in five rooms**, each with its **own picture**: Minerals (20), The Old World (5 – among them a vinyl
  record of the punk band **Pazz**), The Severance (5), The Precursors (5 pieces and 5 tablets), The Dark Ones (5
  pieces and 3 tablets). Each can be found **more than once** and some far more rarely than others (common,
  uncommon, rare, legendary).
- **One house, the floors joined by stairs** (no level of their own): the hall with the curator's desk, behind it
  the grand stairs up to a landing at half height, parting left and right up to the **gallery** round the hall – the
  Old World west, the Severance east; from the gallery two flights meet at a landing and one goes on up to the
  **Precursors** on the second floor. Under the gallery the **minerals room** (the Giant Diamond on its dais, cases in
  the wall, the rest spread out, a miner's statue, an amethyst geode) and the stairs down to the **basement of the
  Dark Ones** – black glass walls with the **reliefs** of their ruins, the cast of a membrane door, the cases round a
  round pool.
- **You fill the cases yourself:** walk up to a case with its piece in your pockets and set it in (the curator pays
  a quarter of its worth); an empty case shows its piece's outline and a "?". **The curator** shows how full each
  room is, buys **spare pieces** (shown already) at their rarity's price (400 / 1 200 / 4 000 / 12 000 cr) and gives
  **hints** where a missing piece is found. **Visitors** stroll about and stop before the filled cases – more, the
  fuller the Museum.
- **A full room gives a perk:** Minerals – rare minerals twice as often; Old World – more standing for relics of
  Earth at the Covenant; Severance – old gates throw you off half as often; Precursors – scanning a third faster; Dark
  Ones – waves and glyphs hurt half as much, and in the basement **a monolith's cast is raised** on its plinth.
- **The whole Museum full:** the **Archivist Suit** – a cloak and a scanner built in (the cloak lasts five times as
  long), the best life support, a deep energy store, a drone place, a long belt, little shield or plate.
- **Where finds come from:** minerals now and then while mining asteroids and in the old mines; the Old World and
  the Severance in wrecks (near the Veil the Severance's); the Precursors' and the Dark Ones' pieces in their ruins and
  hidden caches; their **tablets** from scanning carved tablets and monoliths.
- Debug (F12 → Ground): to the Museum (plaza, hall, basement), cases empty / half / all but one / full, finds.

## alpha 0.7.53.24 – 2026-11-12

**Package 53d – hidden caches and bigger sites (Luz).**
- **Hidden caches:** on a level with carved tablets (the Precursors' vault level) or a monolith (the Dark Ones) a small
  chamber may lie behind a **cracked wall**. Scanning the tablets or the monolith tells of it – it is marked on the
  minimap with a **?**. A cutting torch gets through the wall; the cache behind it holds three times the credits and
  most likely a find for the Museum.
- **Bigger sites:** a site of red danger has one more column and row of rooms (where its shape allows) and one more
  store.

## alpha 0.7.53.23 – 2026-11-12

**Package 53d – the ruin of the Dark Ones (Luz).** Rare and far out (the Far Reaches, near the Veil), a site on the
planet map may now be a **strange ruin**: black glassy stone that seems grown rather than built, ribs, veins of violet
light, carved signs. Its way in is a **maw** with lips of stone – it opens to **symbols touched in the right order** at
the symbol stones beside it; a wrong one sends out a **wave of force** (and the order begins again). A **monolith**
near it shows a vision when scanned – and in it the four signs, in their order.
- Inside, three levels: **round chambers**, ways winding between them, fallen and standing obelisks, bones of
  something vast, altars as cover; **glyphs** on the floor (step on one: a wave); monoliths with visions; a **maw in
  the floor** down, stone steps winding back up.
- At the bottom a **membrane** of living stone – its symbols again – and behind it a vast **pit with something
  sleeping in it** (as a site only scenery; later a job will wake it – a boss). At the pit's edge on an altar a **relic
  of the Dark Ones** for the Museum.
- **Empty** as a site. The new job **"Strange happenings"** (far out) finds a **cult** in it – cultists who rush you,
  zealots with grenades, their priest at the bottom: stop the priest.
- Planet map: the new kind "Strange ruin"; debug tab Missions: the new job.

## alpha 0.7.53.22 – 2026-11-12

**The corporate tower reworked for a real heist (Luz: it could not be done).** Each level holds only **one or two
guards**, and they **walk their rounds** – from room to room along a path, a pause at each stop to look about; walking
they look where they go. Once one of them finds you out, **security comes up the lift** a few seconds later (two,
three or four guards by the danger; on the vault level with the head of security) – once per level. Cameras, light
barriers and the alarm stay as they were.

## alpha 0.7.53.21 – 2026-11-12

**Fix (Luz): trees.** A small tree's crown sits on its trunk now (it floated above it); crowns stay inside their
picture (no flat edges). The roof plaza's trees are as wide as their planters and taller.

## alpha 0.7.53.20 – 2026-11-12

**Package 53d – the research station (Luz).** On harsh worlds (no air to breathe) a site on the planet map may now be
a **research station**: white modules on stilts – their roofs seen from above, their walls a band of windows – a tube
between them, a dome, the radio mast; looters' snow crawler and crates. Two ways in: the **airlock** (its terminal) or
a **torn module** (open, or a buckled plate to cut). Inside, two levels:
- Labs, quarters and stores joined by **long narrow tubes**; lab benches, cryo tanks, sample cabinets as cover; looters.
- **Its own air** – but a **torn module** lets the world outside in (no air, the cold – the suit draws on its energy)
  until you seal its **emergency bulkhead** at the panel beside it.
- A **cold store** with researchers sealed in; toxic samples and a bursting cryo line as traps.
- Below, in the sample store, the **research computer** – its logs are the prize (a lot of research data).
- Jobs: **data recovery** (bring back the logs) and a **rescue** of its researchers (they follow you out).
- Fix: the planet map knows the sites of jobs that are no settlements (a pirate base, a research station) – it could
  not show them before; their approach shows only the landing field.
- Debug tab Missions: rescue (pirate base / research station) and data recovery.

## alpha 0.7.53.19 – 2026-11-12

**Package 53d – the corporate tower (Luz).** In every city the lift now goes up to a **roof plaza** as well: open to
the sky – beyond the glass railing the city with its towers, the sun, speeders and drones (the tower bar's view) –
pale paving, planters with trees, benches, lamps, a fountain, people strolling. At its east end stands the office
tower of a corporation: its glass front with the company's name, the main doors guarded – and round the side, in a
loading bay, its **back door** (a keypad to cut, or a terminal to hack). Inside, three levels:
- **Offices** – pale stone and carpet, desks, pillars, sofas, planters and low screens as cover; **cameras** sweep the
  rooms (seen for a moment: the alarm); a **key card** lies in one of the offices – the lift down wants it; the
  **fire stairs** are quicker, but their door rings the alarm.
- **Security level** – servers and the **security centre**: switch the cameras and the light barriers off (for the
  whole tower), download the company's data.
- **Vault level** – concrete, **light barriers** across the ways (crossed: the alarm), the **round vault door**: hack
  its lock at the terminal, then the drill bites for 20 seconds (loud – the guards come); inside the strongboxes and
  the main box (credits, the company's research data).
- New foes: **corporate guards**, marksmen and the head of security, in navy plate with gold light.
- Jobs: a heist can now go for a **corporate vault** (always hard – an alarm fails it), espionage for a tower's
  **security centre**; both under a city, not on the planet map.
- **Debug: a "Missions" tab** – a button for every job on foot (each heist and spy variant; "Accept & go" lands you
  on the site) and for every kind of space contract, plus "complete all" and "new contracts".
- Fix: the foes' view cones show only while sneaking or in the tactical view (since 0.7.53.18 they showed always).

## alpha 0.7.53.18 – 2026-11-11

**Sneaking reworked (Luz: foes looking the other way, even in other rooms, noticed you at once).**
- **Foes see only where they look – standing too.** An unaware foe has its view (the cone the tactical view shows,
  now also when you stand): standing it reaches further and notices you quicker (about half a second, quicker
  still close by), sneaking nearer and slower, and low cover hides you only when you are low. Out of its view it does
  not see you at all.
- **Noise:** walking close by (55) or running (130) is heard – through a wall half as far; sneaking is silent.
- **A foe that spots you calls out only to those who can see it** (or stand right by it) – no longer through the
  walls into the next rooms.
- **Your lock (R) never wakes a foe**, standing neither – your first shot does; a shot is heard through walls not
  half as far as in the open.

## alpha 0.7.53.17 – 2026-11-11

**Package 53c – the dealer's heist (Luz).** Half the heists now go for a weapons dealer's safe in the sewers under a
city (within two jumps) instead of the Red Talons' hoard: the manhole in the back alley off the shopping street leads
down, the briefing waits in the alley. The safe stands in the dealer's office behind a code door, a turret guards it;
cut it open with a cutting torch. The heist's rules hold here too – easy: an alarm halves the pay; hard: an alarm
blows the job. The site is not on the planet map; the job's progress names the city. Done, the city's sewers are the
ordinary ones again.

## alpha 0.7.53.16 – 2026-11-11

**Healing, power sockets, jobs on foot on their own tab (Luz).**
- **The body mends by itself:** ten seconds without any harm (a hit, the cold getting through, no air) and health
  comes back slowly (1.5 a second) – up to **75 %**; the rest takes a medkit or the clinic.
- **Power sockets** on the walls of a room or two in every site's levels: stand by one and **hold E** – small arcs
  leap from its contacts to your suit and the energy fills (30 a second). Each socket holds 260 energy (its bar shows
  what is left; drawn dry it goes dark). **No shooting while you charge.**
- **Jobs on foot have their own tab** on the bulletin board ("On foot"), four offers per station on top of the
  space contracts – the Contracts tab has as many as before. Labelled by goal: relic race, salvage, bounty, heist,
  espionage, repair, rescue.

## alpha 0.7.53.15 – 2026-11-11

**Fixes from play (Luz).**
- **Combat drones fly** instead of jumping while you walk: they ease toward their place beside you with a speed of
  their own, carried along at your walking pace (they used to switch between full speed and a hover lerp).
- **The ship's keys are locked on the ground** – on foot, on the planet map, in the flight down and at a city's
  hatch: thrust, camera levels, modules, drones, wingmen and the ship commands (G no longer docks you back into the
  ship). The windows, Escape, saving and the debug menu still work.
- **Out the way you came in:** leaving a site with two ways in (a wreck's breach and airlock, the pirate base's
  gates) puts you outside the one you used – no longer always at the wreck's breach.

## alpha 0.7.53.14 – 2026-11-11

**Balancing on foot and a buy-back screen when you go down (Luz).**
- **Heat, cold, poison and vacuum draw on the suit's energy first.** While the suit has energy the life support
  keeps everything out; what its protection does not cover costs extra energy (a suit made for the cold lasts longer
  on an ice moon). Only when the energy is gone does the life support fail and the world outside hurt – all of it.
  The HUD reads "kept out", "kept out, drains energy" or "gets through".
- **All suits carry about 30 % more energy** (Civilian 180, Survey 260, Work 210, Light Combat 220, Pathfinder 260,
  Eyes of the Senate 250, Hand of the Senate 310, Heavy Combat 300 at quality C).
- **Going down on foot has its own screen**, laid out like the one for a lost ship: buy back what you wore and
  carried (suit, weapons, drones, features, belt, grenades, pockets) for **10 % of its price** – the locker aboard your
  ship is not counted, it stays yours. Or take the basic kit (Civilian Spacesuit F, Laser Pistol F, two medkits, an
  energy cell), asked once more. Until you decide you wear the basic kit; the offer is saved with the game.

## alpha 0.7.53.13 – 2026-11-11

**Package 53c – rescue (Luz).** A new job on foot on the board: **Rescue** – the Red Talons hold someone (a freighter
captain, a surveyor, a courier, a doctor, an engineer) in the cells of a pirate base. In a rescue the cells are always
on the first level. Pick the cell's lock (E, a few seconds); the prisoner comes out and **follows you** on a path
round the walls, on the stairs and the ramp too. Explosions hurt them (your own grenades as well) – if they die, the
job fails. Bring them out to the landing field and the job is done; report back for the pay. The freed cell stands
open and empty.

## alpha 0.7.53.12 – 2026-11-11

**Package 53c – jobs on foot (Luz).** About a third of the board's offers are now jobs on foot. Accepting one makes
a site for it – on a body within two jumps (on its planet map) or, for a reactivation, under a city (its lift goes
down to the maintenance tunnels). The goal is fixed; arriving, a **briefing** shows what to do, what counts and the
pay. Done, the site is used up and the job is reported back at its giver for the pay.
- **Relic race** (a Precursor ruin): read the relic – and be quick: after a few minutes another raider crew comes in.
- **Salvage** (a crash site): bring back the flight recorder of a named ship.
- **Bounty on foot** (a pirate base): bring down its captain.
- **Heist** (a pirate base): empty the captain's strongbox – easy: an alarm halves the pay; hard: an alarm blows the
  job (Luz).
- **Espionage** (a crash site, a ruin or a pirate base): download the data from the deepest computer – a bonus if
  nobody saw you.
- **Reactivation** (a city's maintenance tunnels): restart the reactor.
- The rescue (a prisoner who follows you) comes as its own step. The dealer's hideout under a city as a heist site too.
- Debug: `debug_ground_job` (goal). Smoke test group `ground_jobs`.

## alpha 0.7.53.11 – 2026-11-11

**Package 53c – the pirate base (Luz).** Theme sheet in Roadmap.md (Paket 53: Piratenbasis).
- **Outside:** the base is built into a cliff in the north – a big **hangar gate** of welded plates under the Red
  Talons' skull banner (sealed – hack its terminal) and a **side door** with a code lock (cut its box), graffiti;
  **watchtowers** with **searchlights** sweeping the ground (caught in one, every guard comes for you), a scrap fence
  with a gap, gliders parked, fires burning in barrels, crates of loot, guards.
- **Inside:** halls cut into the rock, steel plates welded onto it, red lamps; pirates (raiders, gunners, grenadiers,
  snipers, their captain). **The hangar** – a room as big as it gets – with **a Hornet of the game standing in it,
  plastic** (Luz): its own outline and paint given volume and light, its side, its gear, its shadow; it blocks the
  floor under it and is cover. **Cells** with prisoners (a rescue later). Fires in barrels, scrap barricades, crates.
- **Two levels** joined by a cargo ramp; below, **the captain's hoard** behind a code door – a turret, an alarm; the
  command room's computer opens it. The strongbox is the target.
- Debug: *Site* with theme `pirate`. Smoke test group `pirate`.

## alpha 0.7.53.10 – 2026-11-11

**The reactor room (Luz).** The reactor stands in the middle of its room, its panel wholly inside it; the reactor room
is bigger now so the pit has room round it.

## alpha 0.7.53.9 – 2026-11-11

**Package 53c, first part – the maintenance tunnels, the maintenance drones, the reactor (Luz).** Theme sheet in
Roadmap.md (Paket 53: Wartungstunnel). The place for the coming mission "Reactivation".
- **When a city's tunnels have lost their power** its lift offers the **maintenance level** and goes straight down
  (the service lift takes you back up to the shopping street). For now the debug sets this up; missions will (53c).
- **Three levels** joined by emergency stairwells (green exit signs); technical rooms on a grid. **Pipes everywhere**
  (Luz): runs at several heights and colours along every wall, drops, flanges, valve wheels, cables hanging in loops,
  cracks and rust, a yellow line at the walls' foot; only red emergency lamps. **Pipe bundles on their brackets across
  the floor are cover**, valve housings high cover, cable drums low.
- **Security doors without power:** crank them open by hand (slow and loud) – or put a spare fuse into the fuse box
  beside one.
- **Maintenance drones** (Luz): a quadcopter twice the size of yours in safety yellow, its rotors a blur, a tool arm.
  While they leave you be they fly from spot to spot along the walls and mend it with a cyan beam and sparks; they
  fly over everything. Shoot at one and it turns its cutting laser on you (its light goes red).
- **Traps:** split pipes venting scalding steam now and then, live lines.
- **The reactor** on the lowest level: a round pit, three rings, the core. Restart it at its panel (E-Breach): the
  rings spin up, the core glows, steam rises – and the lights come back on, level by level. The city pays for it.
- Debug: *Site* with theme `maint` (in a city: its tunnels lose their power and the lift goes down). Smoke test group `maint`.

## alpha 0.7.53.8 – 2026-11-11

**The crash site's impact trench (Luz).** Behind the wreck lies the trench it ploughed coming down: as wide as much of
its hull, along its course from the west edge of the field to where it lies – torn-up soil, gouges running along it,
walls of thrown-up earth on both sides, clods scattered beyond; the torn-off stern lies in it. The field has more room
in the west for it.

## alpha 0.7.53.7 – 2026-11-11

**Package 53b – the old mine, a settlement's way down (Luz).** Theme sheet in Roadmap.md (Paket 53: Minenstollen).
- **From any settlement** a path at its north edge (a signpost by it) leads to **the old mine**: the shaft house of
  rusting corrugated iron with its **headframe** – lattice legs, braces, the sheave wheel, the ropes into the shaft –
  the brick winding house, an ore bin on stilts, tailings heaps, rails out of the shaft with lorries, barrels, crates,
  lamps; the path back into town in the south. The **gate** into the shaft is chained (cut it) or hangs open.
- **The drifts:** crooked and branching, few bigger chambers; raw rock with ore glinting in it, timber props holding
  the roof, a lamp cable, **rails down the middle** of the drifts; rock and gravel underfoot, puddles; dim, warm light.
  Cover: lorries, ore heaps, crates, barrels.
- **The cage** takes you to the deeper level – often without power: start the **old generator** by the mine's
  control (loud – everyone down there hears it). It sinks with you.
- **Explosives:** red boxes of them against the walls – a blast close by or a shot that hits one sets it off.
- **A buried side drift:** a fall of rock – blast it with a frag grenade as a charge (or the explosives nearby); behind
  it a cache that may hold a find for the Museum.
- **Traps:** loose rock overhead (it comes down a moment after you pass under it – sneaking you get by), gas pockets,
  tripwires.
- **The target:** in the deepest chamber behind its old gate something glitters in the rock – cut it out: a **special
  mining find for the Museum** (a giant diamond, a singing geode, a fossil in ore, an iron meteorite, a gold nugget).
- For now outposts and research camps have the same old mine at their edge (Luz may give them their own later).
- Debug: *Site* with theme `mine`; *debug_ground_level minehead / settlement* in a settlement. Smoke test group `mine`.

## alpha 0.7.53.6 – 2026-11-11

**Package 53b – crash sites (Luz).** Theme sheet in Roadmap.md (Paket 53: Absturzstelle).
- **Found on the map** like the ruins: a visit may show a crash site instead – and which ship came down (a Longhaul,
  a Mule, a Warden, a Bastion, a Goliath, a Boulevard, a Maul, an Iwakudaki).
- **The wreck is a real ship of the game at the ground's real scale** (15 art px a metre – a 92 m freighter is wider
  than the screen): its own picture, sampled smoothly and laid over with hull plates, seams, rivets, soot and burn
  (`shaders/wreck.gdshader`); its shadow; its stern torn off and lying back along the furrow it ploughed. Fires and
  smoke rising from it, craters and debris, its cargo strewn about – **6 m containers** (lid, ribbed side, door end
  with its bars), one burst open – rocks, engine parts, a scavengers' camp with a buggy (and scavengers).
- **Two ways in on its flank:** a **breach** (open, or a buckled plate wedged in it – cut it out) and the **emergency
  airlock** set into the hull (its terminal on a post beside it – hack it).
- **Inside – a ship's decks:** one long main corridor along the hull, the cabins off it; ship walls with bent and
  scorched panels, torn-out cable bundles, hazard bands, red emergency lamps; deck plates torn up, scorched, foam and
  glass; red, dim light. Cover: lockers fallen over, rows of seats, crates, barrels.
- **Traps:** live conduits across the corridor shock you; a gas leak burns your lungs unless your helmet is on.
- **Two decks:** the floor gave way – climb down through the hole; a ladder takes you back up.
- On the lower deck the **flight recorder** behind a **jammed bulkhead** – cut its box, or route the **emergency
  generator's power** to the bulkheads (the lights die then). The recorder is the target: its owners pay for it.
- Debug: *Site* with theme `wreck` (and `hull`). Smoke test group `wreck`.

## alpha 0.7.53.5 – 2026-11-11

**The dealer's turret and alarm (Luz, package 53b).**
- **A turret** hangs on the office wall and covers the room: when it sees you (in reach, not cloaked, nothing high in
  the way) it turns, rings the alarm and fires bursts – low cover halves its aim, a dodge still works. An EMP stuns
  it; the control room's computer switches it off ("Turrets off").
- **An alarm box** on a guard room's wall: once it rings – the turret spots you, a hack is traced, a tripwire goes
  off – everyone on the level comes for you and **two more** come in from the way you came. Cut its wires first
  (cutting torch) and it stays quiet.

## alpha 0.7.53.4 – 2026-11-11

**The Precursors' ancient lift (Luz).** A new point on every theme's sheet in Roadmap.md: **level change** – how you
get from one level to the next (the sewers: ladder and hatch).
- **The Precursor ruins go two levels deep.** The way down is an **ancient lift**: a round iron platform set into the
  floor in a rusted ring of glyphs, two obelisks with crystals beside it, a console before it.
- **Sometimes it sleeps** (dust and cracks, dull crystals, a red glyph on the console): hack their computer ("Wake
  the ancient lift") or cut open a crystal panel somewhere on the level. Woken, the glyphs glow, lightning leaps
  between the crystals and a column of light stands over the platform.
- **Riding it:** E on the platform – you step onto its middle and it sinks with you into the dark; below you arrive
  on its twin, which takes you back up. The vault with the relic, the tablets and the crystal guardians lie on the
  deeper level.
- A level holds only so many foes now (green 8, yellow 11, red 14); the ruins always have two stores.

## alpha 0.7.53.3 – 2026-11-11

**Package 53b, first part – levels, the structure per theme, and the city's way down: the sewers (Luz).**
- **Every site is rolled anew** (Mystery-Dungeon-like): the theme gives its STRUCTURE – the grid's size (a range),
  how many cells hold a room and how many are junctions where the ways cross, room sizes, the width of the ways,
  loops, the cover per room – and the generator rolls it for each site. What lies where (the things, the traps,
  the foes, the cover) is rolled too. Recorded in the theme sheets in Roadmap.md (new point **Structure**).
- **More cover** (Luz): three to five pieces per room, one at each junction, more along the long ways.
- **Levels:** a site can go down several levels – a hatch in the floor at the far end, a ladder up on the wall where
  you arrive. The target lies on the last level. What you saw of a level stays on its minimap; doors stay open,
  drained tunnels drained, the fallen down.
- **The city's way down:** the lift of a city now also goes to the **back alley** – wet asphalt, brick and concrete,
  lit windows, a neon sign, bins and crates, and on its west side a **building with lifts back up to the shopping
  street** (Luz). In the alley a **manhole**, its cover pushed aside, steam rising: down the ladder into…
- **The sewers (level 1) – long, wide tunnels, few rooms:** walkways of grating on both sides of a **canal** of murky
  water (wade through it – slowly), bridges here and there, pump chambers of wet concrete, walls of concrete blocks
  with a big pipe, streaks, moss and graffiti; **dark** – the lamps glow in it. A **flooded tunnel** bars the way to the
  hatch down: turn the **valve wheel** (loud – the pipes knock) or hack the **pump control** to drain it.
  **Tripwires** with a grenade across the ways – walked into they go off; sneaking you step over them, and with E
  you cut them (and keep the grenade). Cover: pipe bundles, rubble, barrels, old pumps.
- **The dealer's hideout (level 2) – compact, many small rooms:** steel panels put up in the old tunnels, steel
  plates underfoot, warm light; stores with **arms crates**; the office behind a **steel door with a code lock** (cut
  it open, or the control room's computer): a rug, the **dealer's computer** – hack it for the **client list** (the
  site's target: credits now, bounty leads later) – and the **safe** (cutting torch).
- The city's site comes with each visit to the system; done, there is nothing more down there until the next visit.
- Debug → ground combat → *Site (sewer): Green / Yellow / Red*, *Back alley (in a city)*. Smoke test group `sewer`.
- Not yet (later in 53b and 53c/d): the turret and the alarm in the hideout, crash sites, settlements' ways down,
  the Precursor ruins going deeper than one level.

## alpha 0.7.53.2 – 2026-11-11

**Package 53a reworked – the entrance outside, the Precursors' ruin (Luz).**
- **Outside and inside are two maps now.** You land on the site's own ground: the pad in the south-west, and in the
  north a **great ruin** rising out of the ground – a rusted iron facade, glyphs, one **entrance gate**. Sometimes it
  stands open; sometimes it is shut and **hacked** (a Precursor computer beside it) or **cut open** (its panel, with the
  torch). Through it you go inside; the way out brings you back before the gate. Doors stay open, the fallen stay down
  as you go in and out. (Crash sites and pirate bases get their own outside the same way later.)
- **The theme decides how a ruin looks and plays** – recorded in Roadmap.md (Paket 53: wall, floor, doors, computer,
  foes, cover, extras, loot, traps, feeling). First theme: **the Precursors**:
  - walls and floors of **rusted iron panels** with cracks; the floor with holes, rubble and rubbish; the solid mass
    of the ruin dark, so the rooms read as rooms;
  - **old rusted metal doors** (not the blast doors) whose slab rises into the lintel; their wall panels rusted too;
  - an **alien but recognisable computer**;
  - raiders for now (combat robots come with 53f);
  - cover: **fallen pillars** and **ceiling slabs** with rebar;
  - **crystal guardians:** three crystals float around the relic and throw lightning between each other – the
    vault's panel or the computer ("Crystal guardians off") puts them down; until then the relic cannot be reached
    or scanned;
  - loot: scan data, relics, and **finds for the Museum** (collected now, shown with 53e);
  - **traps:** some panels set off an **EMP** – shields, drones and energy weapons are down for a few seconds;
  - **feeling:** fog lies low over the floors and along the ruin's foot outside, and **bursts out** when the gate
    opens.
- Debug: *Site (ruin)* builds the outside; the smoke test group `poi` walks outside → gate → inside → out again.
- Fixed: the view was closed on entering the ruin (the deck check took it for a station); the gate's opening was
  announced twice.

## alpha 0.7.53.1 – 2026-11-11

**Package 53a – sites to explore: the framework (Luz).**
- **Sites found on the map:** when you come into a system, a body you can land on may show a **ruin** this visit
  (about one in three; the same all visit long, new chances next time). The fixed ruins of the landing sites are gone –
  ruins come only this way now. Done with its target, a site is **used up**.
- **Generated:** the drone's pad outside, the site cut into the rock east of it – **rooms on a grid** joined by
  **corridors three tiles wide** (there is fighting in here), the walls' faces made wherever a floor has rock above
  it, the floors cracked. The rooms get **roles**: the entrance, guard rooms (raiders, a leader by the inner door),
  stores (supply caches, one welded shut), a control room (a terminal), a tablet room (3 carved tablets), and the
  **vault** with the target – a relic – behind a **blast door** in its approach's north wall. Three ways in: the box
  on the wall beside the door (cutting torch), the control room's terminal (E-Breach: "Open the door"), or the **air
  shaft** from the room beside the vault (sneak).
- **Themes as data** (`data/poi.gd`): look, foes, props, loot, names – the ruin first; more with 53d.
- **"Possible targets"** – landing at a site found on the map, a window shows what your scanner picks up: what each
  target needs and gives, the danger, the size. Go in, or back to the ship.
- **The minimap** (top right): the site as you have seen it – lines of sight reveal it – with the things you found
  (relic, terminal, caches, doors, tablets, shafts) and you.
- **Supply caches:** E opens them (the welded ones with the torch) – credits and supplies from the theme's loot.
- Reading the relic is the site's target: research data, and the site is used up.
- Debug → ground combat → *Site (ruin): Green / Yellow / Red*, *Reveal the map*. Smoke test group `poi`.

## alpha 0.7.52.29 – 2026-11-11

**The shaft's bend (Luz).** A duct's tiles are now drawn by their neighbours: open where the duct goes on or a room
joins, a wall rim (lit lip, dark shadow) on every other side, the ribs across the way it runs – both ways at a bend.
No stray line through the bend any more, and the wall over a duct has no neon strip.

## alpha 0.7.52.28 – 2026-11-11

**The air shaft, finished (Luz).** The vent's grille sits low in the wall, **flush with the floor**. While it is
shut the **shaft cannot be seen** – it is wall; cut open, the floor and walls are drawn again with the duct in them.
At the shaft's other end a **hatch** lies over its mouth and **flips open onto the floor** as you crawl up to it.

## alpha 0.7.52.27 – 2026-11-11

**The box on the wall, the air shaft (Luz).**
- A maintenance box that opens a **blast door** now hangs **on the wall right beside the door** (flush, its conduit
  running up), no longer on a post in front of it.
- **Ventilation shafts:** a grille in a wall, welded shut – cut it open with the **cutting torch** (its own window: the
  grille with its slats, "AIR SHAFT – KEEP CLEAR"; behind it the duct running off into the dark). Then the **duct** can be
  crawled through; inside it you **sneak** by yourself (and stand up again when you are out).
- **The debug vault** has one: in the start room's north wall, left of the blast door – it runs up behind the vault's
  west wall and comes out inside the vault, past the blast door.

## alpha 0.7.52.26 – 2026-11-11

**Your team cloaks with you (Luz).** Members of your ground team now have a **belt** of their own (as many places as
their suit's belt) for **tools** – given from your pockets on the Pilot window's Gear page, taken back the same way.
When you switch on your short cloak, every member with a **Short Cloak on its belt** (and ready) cloaks with you, for
the time of its own quality, then recharges like yours: foes cannot pick or see it, and it holds fire meanwhile.

## alpha 0.7.52.25 – 2026-11-11

**One lamp on the blast doors, drones outside a fight, the short cloak (Luz).**
- **Blast doors:** one lamp beside the frame instead of the three – red shut, amber blinking while it opens, green open.
- **Drones outside a fight:** they sit on your suit everywhere now (on the back, or at the upper arms on the Senate
  armours), and **C / Shift+C** sends them up there too – they hover by you and follow you (no fighting where there is
  no fight), the same key brings them back to their dock.
- **Short Cloak** (new belt tool, Axiom Astronautics, qualities F–A, 2400 cr at C): on its belt key you are **unseen**
  for a few seconds – **F 2 s, D 3, C 4, B 5, A 6** – foes lose you (they cannot shoot at you or pick you, unaware ones
  cannot notice you; your team can still be shot), and **your weapons hold fire** meanwhile. Then it **recharges**:
  **F 30 s, D 27, C 24, B 21, A 18**. The pilot shimmers half-seen; beside the dodges: "CLOAKED 3.2 s" / "cloak
  recharging 20 s".
- Smoke test group `foot_cloak`.

## alpha 0.7.52.24 – 2026-11-11

**E-Breach, more belt places, new blast doors (Luz).**
- **E-Breach** – a new consumable (stacks of 5, 350 cr, in the gear shops' consumables): hacking a terminal takes one
  from your belt, used up with the try. Without one you cannot jack in. (The **cutting torch** on your belt was already
  what starts the cutting – the box asks for it.)
- **Belt places:** every suit has at least **3**, the light and heavy combat suits (also the Senate armours) **4**.
- **Blast doors redesigned** after Luz's pictures: an **octagonal plate** set in a recessed frame, two parallel
  diagonal seams cutting it in three, mottled grey steel, jamb slots, a service hatch on the wide one, lamp strips of
  red, amber and white beside the frame. Opening, the outer parts slide into the walls and the middle one rises. Two
  sizes: **small** (narrow and tall) and **wide**.
- **The debug vault** now has the **wide** door in front and a **small** one in the vault's back wall – the terminal
  opens it ("Open the door"), behind it a niche with a carved tablet.

## alpha 0.7.52.23 – 2026-11-11

**The debug vault (Luz).** Debug → ground combat → *Explore: The vault (station room)* takes you into a closed room
inside a space station (air, no helmet needed), with a cutting torch and a scanner on your belt:
- at the top of the room a sealed **blast door** – heavy leaves with yellow chevrons, its lock, red warning lights;
- beside it a **maintenance box** (notched flap): cut it open, the **button** behind it opens the door – the leaves
  slide into the walls, the lights turn green;
- behind the door the vault: a **relic in a laser cage** (four posts, red beams at three heights, its red glow) – the
  scanner cannot read it through the lasers;
- at the side a **terminal**: hack it and choose **"Laser cage off"** – the beams and the glow go out; then **scan the
  crystal**. The airlock at the south takes you back to your ship.
- Smoke test group `foot_vault`.

## alpha 0.7.52.22 – 2026-11-11

**Package 52b, part 2 – the cutting torch, hacking, scanning (Luz).**

- **Maintenance boxes:** with a cutting torch on your belt, E at a box opens it close up – a heavy steel housing
  (frame and bevel, bolts, rivet seams, hinges, a handle, a vent, warning stripes, its plate and a blinking light,
  conduits, rust streaks, a barcode). **One flap per box, each box its own shape** (rounded, hexagon, round, trapezoid,
  notched, arched). **WASD** moves the torch, **Space** burns: on the line the cut glows and runs on, off it the plate
  scorches and heats – too hot and the torch has to cool; the suit pays the energy. Cut all round, the flap falls
  away and shows the **machinery behind it**: a recess with depth, a mounting plate, conduits, a heat sink, a relay,
  fuses, a circuit board with chips and blinking LEDs, bundles of coloured wire with ties and tags – and either a
  **button** in its striped collar (Space: press) or a **terminal** with its screen, keypad and jack (Space: jack in).
  Engineering and the torch's quality widen the line and slow the heat.
- **Hacking – the security grid:** your probe goes node by node with **WASD** from your jack to the **core**; red
  **tracers** run their loops – touch one and the trace climbs, at three you are locked out and the alarm wakes the
  foes near; the core sits behind a **lock** only the **gold key** opens; the clock runs. Electronics slows the tracers
  and gives more time. Done, you choose with W/S and Space: open the door, power off/on, turrets off, cameras off,
  download data (research data).
- **Scanning:** at a carved tablet or a relic, **hold the scanner's belt key and stand still** – a beam sweeps it, a
  ring fills (about 3 s, quicker with Science). Moving or letting go breaks it off. A tablet gives its inscription,
  both give research data.
- Doors, lights, turrets and cameras to work them on come with the places to explore (package 53); for now the debug
  arena has them: Debug → ground combat → *Explore: box, terminal, tablet, relic here* (with a torch and a scanner).
- Smoke test group `foot_explore`.

## alpha 0.7.52.21 – 2026-11-11

**Package 52b, part 1 – sneaking (Luz, after the concept she approved).**

- **Ctrl** switches sneaking on and off (rebindable – Ctrl can be bound now). Half speed, no running; you are drawn
  low with a violet ring.
- Unaware foes then do **not hear** you and **see you only in their view** – a cone that sways slowly as they look
  about, shorter than their sight; **low cover hides you**, smoke too; right next to them they notice you anyway. In
  their view they need a moment to spot you: over their heads "zz", then a yellow "?" filling up.
- The tactical view shows in red **where they would spot you**, with a line on top.
- **R** locks an unaware foe without it noticing, and you may open fire: **the first shot on an unaware foe does double
  damage** ("sneak attack ×2"). Shots are heard as before.
- Your team, following you, sneaks too and cannot be spotted.
- Smoke test group `foot_sneak`.

## alpha 0.7.52.20 – 2026-11-11

**Package 52a – the ground team (Luz, after the mockup she approved).**

- **Who comes along:** up to **two crew members of the active ship** – picked at the top of the Pilot window's Gear page.
- **Their gear:** the same page shows each member's suit and weapons; suits and weapons go to them from your pockets
  and come back the same way. Without a weapon they carry a slug pistol; their rounds and energy are their own.
- **About as good as foes** (Luz: much weaker than you): body, aim and damage share by their quality (F–A).
- **How they fight** (set per member): aggressive (close in), careful (cover near you), flanking (round the side).
  They pick your target when they can see it, else the nearest foe; foes shoot at them too when they are much nearer.
- **The command wheel on V:** a tap picks whom the orders go to (one member or all), holding V opens the wheel round
  you (time runs slow) – *Follow me*, *Attack my target*, *Hold here*, *Ability*; letting go gives the order.
- **Abilities by profession:** Gunner suppressing fire, Engineer shield dome, Science Officer scan (their cover stops
  counting), Drone Operator jammer, Quartermaster resupply, Mining Foreman demolition charge, Co-Pilot flank run.
- **Down and dead:** down in a fight, **hold E beside them** to bring them back (45 s). Left down too long or behind,
  they die – a **clinic brings them back for a fee** by their quality; until then they are missing aboard as well.
- **On screen:** their cards under your bars (portrait, profession, shield and body, order, the ability's ring), cyan
  rings at their feet (apart from the foes' green), a flag where they hold.
- Debug: Team buttons in the ground-combat section (two companions, one down, revive, abilities ready, down one dies);
  smoke test group `foot_team`.

## alpha 0.7.52.19 – 2026-11-11

**Calling a kamikaze drone back (Luz).** While a kamikaze drone is up in the air, a tap on its key (C, or Shift+C for
the second) still sends it at your target; **holding** the key calls it back to its dock, switched off.

## alpha 0.7.52.18 – 2026-11-11

**The Assembly's Senate armours (Luz's idea, after the mockup she approved).**

- **Eyes of the Senate** (light, Concord Fleetworks): bright blue plate with white sweeps over the chest, forearms and
  shins, white-edged pauldrons, a closed helmet with a dark V visor and a short dark-blue **crest**. Shield 80, armour
  50, quick on its feet; 2 weapons, 2 grenades, 3 on the belt, **2 drone places**, 2 features.
- **Hand of the Senate** (heavy): deeper blue, broader, a white mark on the pauldron, a **deep-blue cloak** down its
  left side and a tall crest sweeping back. Shield 110, armour 115; 3 weapons, 3 grenades, 2 on the belt, **2 drone
  places**, 3 features.
- **Two drones**: both sit switched off at shoulder height on the outside of the upper arms, their undersides against
  the arm (edge on from the front and behind, the near one whole from the side). **C** flies the first, **Shift+C** the
  second (in the hotkeys); each has its own tile, fights, reloads, is shot down and rebuilt on its own.
- Only in the Assembly's lands and only for pilots it calls Friendly.
- Smoke test group `foot_senate`.

## alpha 0.7.52.17 – 2026-11-11

**The arm laser's beam holds 2.5 seconds (Luz).** It stays on its target and follows it, burning in ten bursts (its
120 damage shared out, a hit roll each); if the target falls it goes out early. The cut, the sparks and the hiding in
cover move with it, and the deep hiss lasts as long.

## alpha 0.7.52.16 – 2026-11-11

**The arm laser vanishes into the cover it cuts (Luz).** The beam now disappears where it enters a piece of cover and
shows again only past the end of that piece's picture – also behind the top of a tall bulwark; in front of cover it
stays in sight. With the glowing cut and its sparks it looks as if it really cuts through.

## alpha 0.7.52.15 – 2026-11-11

**The Red Arm Laser: a deep hiss and sparks where it cuts (Luz).**

- **Its own sound** (`w_arm_laser`): a deep, rushing hiss with a dark rumble under it and a faint sizzle on top –
  instead of the light laser "pew".
- **It visibly cuts through cover**: wherever the beam goes through a crate, a barrier, a bulwark or a wall, the cut
  glows white-hot and a spray of sparks flies out to the sides and onwards, falling, for as long as the beam lasts.
- The target's lock card shows the arm laser's real chance through cover (it cuts through, cover does not count).

## alpha 0.7.52.14 – 2026-11-11

**The Covenant's Pathfinder armour (Luz's idea, after the mockup she approved).**

- **Pathfinder Armour** (Forge of Return): red plate edged in gold, close-fitting and straight-lined – a gold pointed
  arch on the chest, a gold belt line and knee caps, a sleek helmet with a gold crest and a **pointed-arch visor** in
  gold. Strong plate (armour 130 at C – more than the heavy combat suit), shield 45, normal walking speed; 3 weapon
  places, 2 grenade places, 2 on the belt, 2 features – **no drone place** (the Covenant will not have them).
- **The Red Arm Laser** sits in its first weapon place, built in: it cannot be taken off, it goes with the suit. A heavy
  beam from the left forearm (120 damage at C) that **cuts through any cover**, even bulwarks and walls. Then it takes
  **30 seconds** to charge – also while another weapon is in hand. Its tile's frame is drawn round in yellow as it
  charges; full, it is ready. While it is the weapon in hand the pilot **raises the left arm** towards the target, the
  beam leaves the emitter at the wrist.
- **Only in the Covenant's lands** (its bigger stations and cities, and military ones) and **only for pilots it calls
  Friendly**.
- Smoke test group `foot_pathfinder`.

## alpha 0.7.52.13 – 2026-11-11

**Tiles along the bottom, the events on the right, a closer zoom (Luz).**

- **Tiles as in space combat** along the bottom: the **weapons** (the one in hand framed green), a little apart the
  **grenades** (the one in hand framed red), then the **drone** (its state, heat or rounds, the time to a new one) –
  each with its picture, name and what it holds; Q, X and C go through them as before. The belt's places stay on 1, 2, 3
  … – now tiles too, bottom left. The weapons panel on the right is gone; the dodge charges sit under the suit's bars.
- **The events on the right**, as in space: everything that used to pop up in the middle at the bottom – and the
  game's messages – runs into a log at the bottom right, with the time. The "[E] …" prompts of the place you stand at
  stay in the middle.
- **A closer zoom (×1.5)** in the fight and in the tactical view: the mouse wheel steps through the zoom (the fight:
  normal and near; the tactical view: out, normal and near), Z switches near and back (in the tactical view: out and
  back).

## alpha 0.7.52.12 – 2026-11-11

**Drones that turn and sit on your back; ammunition to be had (Luz).**

- **The drone turns where it flies** – and towards its target when it fires: the whole picture with its rotors turns.
- **Switched off on your back** until you press **C**: its underside against you – from behind you see it flat on your
  back, from the side its edge behind you, from the front you hide it. C sends it up; C again brings the laser and
  kinetic drones back to your back and switches them off. The **kamikaze** takes C twice: once to take off, once to send
  it at your target. A kinetic drone reloading on your back takes off again afterwards (C meanwhile: it stays there).
  On your back foes cannot shoot it.
- **Ammunition refilled**: the supply points by the pads (were "charging points") now fill energy, oxygen **and
  rounds**, and so does your ship when you go aboard – before, only ammunition boxes did.

## alpha 0.7.52.11 – 2026-11-11

**Ground combat drones (package 52.6, after the mockup Luz approved).**

- **A drone place on both combat suits** for a drone module, quality F–A (more damage, heat it bears or rounds it
  holds, shield and armour). In the Gear shop under Features → Combat drones, where combat suits are sold; on the gear
  page a row of its own.
- **They take off from your back** and hover at your shoulder – small quadcopters about 0.6 m across, spinning rotors,
  a blinking light, a shadow on the ground.
  - **Laser drone** (Axiom): fires at your target by itself; every shot heats it, full it must cool off.
  - **Kinetic drone** (Hadrian): a quick slug gun; its magazine empty, it flies back to your back and **reloads from
    your suit's rounds**.
  - **Kamikaze drone** (Forge of Return): waits at your shoulder; **C** sends it diving at your target, where it bursts
    (it spares you).
- **C** – the drone's command (rebindable): the kamikaze dives, the others are called back to your back or sent out
  again.
- **Foes shoot at it** – half the time when it is nearer to them than you are. Shot down, it falls; **a new one** takes
  off after 20 s (the kamikaze after 50 s).
- A drone panel beside the weapons: what it does, shield, armour, heat or rounds, the time to a new one.
- **More rounds and energy for every suit** (Luz): e.g. the light combat suit 240 rounds and 170 energy (was 160 /
  120), the civilian suit 100 / 140 (was 60 / 100).
- Debug (F12 → Ground → Combat): a laser, kinetic or kamikaze drone in any quality, shoot it down, a new one now.
  Codex entry; smoke test group `foot_drones`.

## alpha 0.7.52.10 – 2026-11-11

**Fix: ruins and crash sites in the approach without settlement pads.** Seen from above on the way down, a ruin or a
crash site now shows only the one landing field the drone sets down on – not the four pads of a settlement.

## alpha 0.7.52.9 – 2026-11-11

**Grenade places, the grenade on X, Shift+R, small bars over foes, softer radar colours, the controls in two tabs
(Luz).**

- **Grenades have places of their own** on every suit, apart from the belt's consumables and tools: civilian, survey
  and work suits 1, the light combat suit **2 grenade places + 3 on the belt**, the heavy one 3 + 2. Grenades go there
  when put on (the gear page shows them as their own row); **grenades stack up to 10**, in the pockets and in their
  places.
- **One grenade in hand**, as with the weapons: **X** tapped takes the next kind, **X held** shows the arc to the mouse,
  let go throws it. The weapons panel shows the grenade in hand and how many. The number keys are the belt's alone.
- **Shift+R** locks the foe nearest to you; R still goes round them all.
- **Small shield and health bars** right over every foe's head.
- **The tactical view's colours a little softer** – the red, the green and the yellow.
- **Controls in two tabs, Space and Ground**, and every key on foot can be changed: walking, use, **run** (its own now,
  apart from the ship's thrust), **belt places 1–4**, next target, nearest target, grenade, dodge, other weapon, tactics,
  zoom. Bindings can be Shift+key (hold Shift while pressing the key; Shift alone when let go on its own). Saved on-foot
  bindings reset once to the new defaults.
- Debug "Fill the grenade places"; smoke tests extended.

## alpha 0.7.52.8 – 2026-11-11

**The tactical view zoomed out on demand (Luz).** While the tactical view is open, **Z** or the mouse wheel (down)
zooms the camera out to half – the whole reach of your weapon and the cover around it in sight; Z again or the wheel
(up) brings it back. It eases in and out, goes back to normal when the view closes and is remembered for the next time.
The legend shows the key; the key can be rebound ("On foot").

## alpha 0.7.52.7 – 2026-11-11

**The tactical view in the other side's colours (Luz).** In your green view the shadows – where foes are covered from
you – are now red; in a foe's red view the shadows – where you are safe from it – are green. The ground behind smoke
shows yellow and hatched in both. Legend and codex follow.

## alpha 0.7.52.6 – 2026-11-11

**Shield domes and smoke in the tactical view; the foe's view at its own weapon's reach (Luz).**

- **Shield domes** cast their shadow in the tactical view when seen from outside: in a foe's red view everything in
  the dome and behind it is dark – safe from it; from inside, your own green view goes out freely. In the fight, too, a
  shot from outside that crosses a dome now breaks on it, even when its target stands beyond it.
- **Smoke** marks, from the chosen side, the area behind the cloud – grey and hatched: shots into or through it aim
  badly (a third of their chance). The legend says so.
- **The red view reaches as far as the foe's own weapon** (labelled with its name and metres), so you can see how far
  it can shoot; your green view stays at your weapon's reach.

## alpha 0.7.52.5 – 2026-11-11

**Grenades, pirates and guards, and foe types with tactics of their own (package 52, the next round).**

- **Throwing grenades:** hold a grenade's belt key – a dashed arc to where the mouse points (up to ~13 m) and the
  blast's reach; let go to throw. A quick tap throws at the locked target. **Frag** (explosive, less further out, half
  behind low cover, nothing behind high cover), **EMP** (knocks shields down), **smoke** (a cloud: shots through it keep
  a third of their chance, foes do not see through it), **shield grenade** (a dome: fire and blasts from outside break
  on it and wear it down, your own fire goes out through it).
- **Foe types, each with its own tactic:** rusher (closes in, sidesteps), rifleman (cover facing you, moves on when
  flanked), **holder** (keeps its spot, sprays in bursts), **flanker** (runs round to your open side while the others
  pin you), **thrower** (keeps back and throws frag grenades as soon as you settle behind cover – their grenades show
  where they will land in red), **leader** (further back; its band keeps near it and loses heart when it falls), and
  Luz's **sniper** (90 % of its reach, in cover, far better aim, far slower fire – a red aiming line warns of its shot).
  Anyone with grenades throws one if you sit too long behind the same cover.
- **Pirates (Red Talon):** raider (flanker), gunner (holder), grenadier (thrower), sniper, captain (leader) – combat
  suits in black plate with red lights. **Guards:** trooper, heavy, sergeant (they only fight where weapons are allowed
  – for now the arena). The bandits' gunner holds, their boss leads.
- **Debug:** "Arena: pirate crew", "Arena: guard squad", "Arena: one sniper", "Grenades on the belt"; every foe kind in
  the spawn list. Codex entry, smoke test group `foot_tactics`.

## alpha 0.7.52.4 – 2026-11-11

**Threat tiers – a coloured ring at every foe's feet (Luz).**

- Every foe has a tier: **green** (very easy), **yellow** (middling) or **red** (dangerous), shown as a ring on the
  ground at its feet (with a dark edge, readable on any ground) and as a dot on its lock card.
- The tier scales the foe: body ×1 / ×1.6 / ×2.5, damage ×1 / ×1.7 / ×2.7, aim (Firearms) +0 / +2 / +4 and its gear's
  quality +0 / +1 / +2 steps (a rifleman's E rail carbine becomes a C one at red).
- Debug (F12 → Ground → Combat): **"Arena: 2 green + 1 yellow"** and **"Arena: 2 yellow + 1 red"**; the tier can be
  chosen when spawning foes. Codex entry and smoke test extended.
- Roadmap: the new foe types with their own tactics (flanker, thrower, leader – and Luz's **sniper**: 90 % of its
  reach, in cover, far better aim, far slower fire) moved to the next round; **ground combat drones** (laser, kinetic,
  kamikaze – launched from the pilot's back) noted for the end of the combat mechanics.

## alpha 0.7.52.3 – 2026-11-10

**Weapons with detail, shots from the tip, mightier fights, the tactical view at your weapon's reach (Luz).**

- **Every hand weapon has its own pixel picture** at the figures' fineness and in real size (pistols ~0.3 m, rifles
  ~1 m, the Long Rail ~1.5 m), in its maker's look: Axiom white with cyan cells, coils and emitters; Hadrian gunmetal
  with amber sights, rails and magazines; Forge of Return dark bronze with red glow seams, the scatter gun's double bore
  and pump, the Long Rail's scope and bipod; Concord's blue-white cutting beam with its focusing head; the olive
  grenade launcher with its drum. Held at chest height, turned straight at the target and mirrored when aiming left;
  facing away, the weapon is behind the body.
- **Shots leave the very tip of the weapon** – lasers, slugs and shells, for you and for the foes – in line with the
  barrel.
- **Mightier fights:** foes hit for 12 % of their weapon's damage (was 30 %) and have weaker bodies (scrapper 55,
  rifleman 60, gunner 65, boss 100 against your 100) – one against three is fairly easy with decent gear; standing in
  the open still hurts.
- **The tactical view reaches exactly as far as the weapon in your hands** – the green view and the red one (the
  target's sight within your reach) – with a clear ring at the reach, labelled with the weapon and its metres.

## alpha 0.7.52.2 – 2026-11-10

**The tactical view on Tab, the next target on R (Luz).**

- **R** locks the next target now (as R locks in space); a click still locks any foe.
- **Tab** opens the **tactical view**, drawn like the radar in space and lying on the ground under people and cover: a
  disc as far as your weapon reaches, with rings and a sweep. **Green** is everything in your sight; every piece of
  cover leaves its **radar shadow** – nothing behind bulwarks and walls, and right behind crates, barriers, rocks and
  barrels the dark band where a foe is covered from you (beyond it you shoot over the cover again). So you see where
  they hide and how to get round them.
- **Tab again** switches to the **red view – the locked target's sight** (its own weapon's reach): red it can hit, its
  shadows are where you are safe from it; the line at the top tells you whether you stand in its sight. Tab again goes
  back to your sight; **holding Tab** closes the view.
- Saved key bindings of the on-foot fight keys reset once to the new defaults. Debug: the tactical view from the
  Combat section; codex entry and smoke test extended.

## alpha 0.7.52.1 – 2026-11-10

**Package 52 begins – fights on foot (hybrid, after the mockup Luz approved).** For now in the **debug arena**
(F12 → Ground → Combat; the real places to fight come once the system stands – Luz).

- **Locking as in space:** when a fight starts the nearest foe is locked by itself (Luz: yes); Tab locks the next, a
  click on a foe locks it, a right click lets it go – up to three targets with red brackets (T1–T3), the active one
  thick, a short lock-on arc; lock cards top centre with name, distance, hit chance, their weapon and the bars for
  shield, armour and health.
- **The weapon fires by itself** at the active target when it is in reach and in sight; the hit chance comes from the
  weapon's steadiness, **Firearms**, the distance (past about half the reach it falls off), and the target – running,
  on a stimulant, in cover. Lasers draw the suit's energy, slug guns and launchers ammunition; Q puts the other weapon
  in hand. Shots fly (lasers at once), misses fly past and stop at high cover, damage numbers in the colour of the
  layer they reached.
- **Shield → armour → health** with the damage types' weights as on the ships; the suit's shield comes back after four
  quiet seconds on its energy, armour is mended aboard. The suit's bars now show shield and armour as they are.
- **Cover from the map:** crates, rocks, barrels and the new plated **barriers** are low cover – you shoot over them,
  shots at someone right behind them mostly end in them ("blocked", sparks); the new **bulwarks**, walls and the ship
  are high cover – no sight through them. A green half-ring and the line "IN COVER / PARTLY IN COVER / OUT IN THE OPEN"
  show where you stand.
- **Dodge on Space** (Luz: yes): a quick jump in your walking direction (sideways to the target if you stand), no shot
  lands during it; charges and their recharge from **Athletics**, jump jets make it ×1.6 longer.
- **Bandits** (Dust Rats): the scrapper rushes in with a scatter gun, the rifleman takes cover at range, the gunner
  sprays from a spot, the boss leads from cover with a laser rifle and a real shield. They notice you (sight, shots
  heard), call to each other, seek cover facing you and move on when you get round it, run when badly hurt, and fall.
- **Going down in a fight:** you wake in the clinic ("You went down in the fight"), the pockets emptied.
- **The weapon in the hands** of whoever fights, pointed at the target; the helmet closes for the fight.
- **Debug (F12 → Ground → Combat):** open the arena (world type to choose, with three bandits or empty), spawn any foe
  (quality, number, far or near), all foes down, end the fight, freeze them, the **AI view** (low and high cover, sight
  lines, states, layers, both hit chances), hit yourself or go down now, Firearms/Athletics 0/5/10; the status line
  shows the fight.
- Codex entry "Fighting on foot"; Athletics and Firearms now work (skill tree); keys Tab / Space / Q in the "On foot"
  group; smoke test group `foot_combat`.

## alpha 0.7.51.20 – 2026-11-10

**Fix (Luz): the hangar's guide line no longer runs through the wall by the lifts** – it stops at the wall and goes on
behind it.

## alpha 0.7.51.19 – 2026-11-10

**The hangar's wall by the lifts thinner (Luz).** The wall that sets the lifts apart is now a single tile thin, its top
along the end of the glass front and its face reaching down into the walkway; the glass runs its full length again.

## alpha 0.7.51.18 – 2026-11-10

**The hangar's lifts in a room of their own (Luz).** Between the glass front and the lifts the wall now juts out a row
into the walkway – two tiles wide, at full height – so the lifts sit in their own alcove; the walkway past it stays two
rows wide, nobody is placed inside the wall.

## alpha 0.7.51.17 – 2026-11-10

**Fix (Luz): the hangar's wall ends at full height.** On the hangar walkway the walls at both ends of the glass front
(by the stairs and by the lifts) now show their face like every other wall instead of only their top.

## alpha 0.7.51.16 – 2026-11-10

**Fix (Luz): more walls at full height.** The lift lobby's wall where it ends at the corridor (stations, cities) now
shows its face like every other wall; in the settlements the shop block's outer wall on its south side shows its full
height out in the open instead of only its top.

## alpha 0.7.51.15 – 2026-11-10

**Fix (Luz): the shops' back walls as high as every other wall** – on the stations' commercial level, in the cities'
shopping streets and in the settlements. Each shop's back wall now shows two rows of face like the lobby, the clinic
and the hangar; the shops are a row deeper so there is as much room inside as before, and their doors go through the
whole wall.

## alpha 0.7.51.14 – 2026-11-10

**Fix (Luz): the clinic's scanner out of the doorway.** The auto-surgeon with its scanner screen moved two tiles to
the left, clear of the treatment room's door (the easter egg moved with it).

## alpha 0.7.51.13 – 2026-11-10

**The clinic's lobby walled, and an easter egg (Luz).**
- The lift lobby is walled off from the corridor – a full-height wall face like the others (the end of the wall by
  the reception too); the way in leads through the reception.
- The auto-surgeon has a scanner screen at its head – glass in a frame with a scan line. **Step behind it and you
  show as a skeleton.**

## alpha 0.7.51.12 – 2026-11-10

**Fix (Luz): the clinic's walls along the corridor as high as the others.** The wall between the wards (and the
aesthetics studio) and the corridor showed only its top; it now shows its face to the corridor like every other wall,
its doors cut through it. The corridor and the rooms south of it moved down two rows.

## alpha 0.7.51.11 – 2026-11-10

**The clinic, a level of its own (Leitlinien 4, Luz).** Mercy Hall is no longer a room in the shop row – the lift
takes you there, on stations and in cities that have one ("Clinic – Mercy Hall, treatment and recovery").
- **The lobby** by the lifts; **the reception** with the hall's sign, screens, its counter with a nurse and a
  doctor (the treatment window), waiting seats and plants.
- **The wards** (Ward 1 and 2) along the corridor: two beds each with their patients (on the pillow, a drip, the
  monitor), a medicine cabinet, staff by the beds.
- **The recovery room** – where you come to now, beside a bed (after a lost ship, after a fall on foot); **the
  treatment room** with the auto-surgeon (a capsule under glass, its arm, its screen); **the pharmacy** with its
  cabinets and counter.
- **Aesthetics – Visage** (Luz): the image studio moved in as a room of the clinic – a sculpting chair under its
  scanner ring, a holographic bust of the face being made, a stylist, a sofa; the character editor opens there. Where
  a station has a clinic, the image studio leaves the shop row.
- Doctors in white coats, nurses in sky blue; clean light floors and walls, the clinic's colour in its signs and
  lights. The lifts name the clinic; F12 → Ground can go straight to it.
- Smoke test: the clinic's level (treatment window, image studio, recovery room, lifts), not in the shop row, the
  image studio in the shop row only without a clinic, waking in the recovery room, the debug level.

## alpha 0.7.51.10 – 2026-11-10

**The suits each their own, the combat suits dangerous, the helmet when you want it (Luz).**
- **Combat suits:** plates over a black undersuit – a chest plate with its seam and lights, a segmented belly,
  pauldrons, thigh, knee and shin plates, gauntlets. The **Light Combat Suit** white with cyan lights, its closed
  helmet with a broad dark visor and jaw guard – in profile the visor juts forward and the back flares; the **Heavy
  Combat Suit** gunmetal with red lights, broader, its pauldrons standing out past the arms, an antenna off its pack,
  a T-slit visor lit red.
- **Civilian and Survey Suits:** a hard white EVA helmet with a gold sun visor (the survey helmet with lamps and a
  camera at its side); the survey suit's cyan seams and shoulder sensor pod. **Work Suit:** reflective bands, a chest
  box with its lights, a hard yellow helmet with a lamp. Gloves on every suit.
- **The powers' guards** wear the combat suits in their power's colours, helmets on – Independent gunmetal with neon
  cyan, Assembly pale blue-grey with blue, Covenant dark red with gold, Directorate white with green; some posted
  guards in the heavy suit.
- **Helmet: When needed / Always** on the Gear page (saved): when needed it is on where the air cannot be breathed
  and in a fight (the fight trigger is ready for combat on foot, which comes later); always – outside and aboard.
- Smoke test: every suit looks its own with and without its helmet, the guards' four liveries, the helmet setting
  saved.

## alpha 0.7.51.9 – 2026-11-10

**Fix (Luz): the Gear shop showed itself twice, one under the other.** The shop did not clear itself when it was
rebuilt – after a purchase or when the window changed its size the new front was stacked under the old one. It now
starts afresh on every rebuild. Smoke test: after rebuilds there are still exactly four tiles in front.

## alpha 0.7.51.8 – 2026-11-10

**The Gear shop rebuilt (Luz, with a sketch).** Three steps deep, with pictures, instead of one long list.
- **The front:** four big picture tiles in a showroom lit in the shop's colour – **Suits** (the pilot standing in a
  suit on a lit plinth), **Weapons** (a gun rack), **Features** (the suit's modules), **Belt** (tools, grenades,
  consumables) – each with how many pieces this shop has; under them *Sell from your pockets*. The tiles share the
  window's width and grow with its height (they follow the window when it is resized).
- **A category's kinds** as picture tiles: Suits – Civilian & work, Combat; Weapons – Lasers, Slug guns, Explosive;
  Features – Defence, Movement, Life support & supply; Belt – Tools, Grenades, Consumables. A kind the shop does not
  carry is dimmed.
- **A kind's list:** each piece with its picture, name and description, its numbers in columns (weapons: damage,
  rate, range, what a shot uses; suits: slots, shield, armour, energy, air, speed; features and belt: their effect)
  and a button per quality F–A in the quality's colour with its price – the numbers at that quality on the button's
  tooltip; qualities this shop does not carry are greyed.
- A path along the top (GEAR › WEAPONS › SLUG GUNS) with *‹ Back*, the free pocket places and your credits.
- Smoke test: four tiles in front, three kinds of weapons, a list with quality buttons, buying from it, the front's
  height following the window.

## alpha 0.7.51.7 – 2026-11-10

**The Gear page like the ship menu (Luz).** The pilot window's Gear tab now follows the pattern of the ship menu's
FITTING – tiles with pictures instead of lists of buttons.
- **Left, the suit as a mockup:** the pilot standing in the suit they wear (helmet on), its name in the quality's
  colour, maker, quality and slots; health, shield, armour, energy, oxygen and ammunition as coloured bars; the
  protection against heat, cold, toxic air and vacuum as bars; walking speed.
- **Below it, the piece picked** (like "Select a module"): its picture, name, where it sits, everything it does – and
  the buttons for it: *Take off → pockets* (worn), *Put on* and *→ Locker* (in the pockets), *← Into the pockets*
  (in the locker).
- **Right, tiles:** Suit, Weapons, Belt (each place with its key 1–n), Features, the 12 places of the Pockets and the
  ship's Locker (aboard or in the hangar) – frame and corner in the quality's colour (F–A), stacks with ×n, the tile
  picked framed green.
- **A pixel icon for every piece** (new `gear_icons.gd`, 24×24 like the module icons): the suits in their colours,
  lasers glowing cyan, slug guns in steel, the launcher, grenades, scanner, cutting torch, mining laser, medkit,
  stimulant, energy cell, oxygen, ammunition, and the features (shield generator, plates, sprint booster, jump jets,
  temperature regulator, oxygen reserve, ammunition pack, battery).
- Smoke test: every piece has its icon, the page shows a tile for the suit, each slot and each pocket place, and
  picking a piece in the pockets and *Put on* puts it on.

## alpha 0.7.51.6 – 2026-11-10

**Sci-fi buildings on the ground (Luz: "buildings that look like suburban houses won't do at all").** Every building
of the settlements rebuilt as a real sci-fi building, at the realistic scale (a storey ~2.6 m, doors 2 m) – no pitched
roofs, planks, shutters, flower boxes, rubble stone or adobe any more.
- **Eight architectures:** Independent – the armoured **hab** (big plates with bolted seams, heat-exchanger fins on
  the roof, deep rounded windows, a pressure door under a plated canopy, neon sign, cables), **stacked hab pods**
  with light seams and a steel stair, **pressure halls** of armour segments with glowing seams; Assembly – the
  **terrace** of pale composite and glass (a glass front per storey, a terrace with a glass railing, roof gardens, a
  glass dome) and **habitat domes** with a glazed crown; Covenant – the **spire** of great dark red-brown slabs,
  buttresses with gold lines of light, lancet windows lit gold, a parapet of pointed merlons and a spire, red
  banners, a metal blast door in a pointed gold frame; Directorate – white **modules** with a hexagonal crown and
  solar panels; dry worlds – **printed regolith** (smooth, faint layers, rounded, slot windows behind louvres, a
  portal round the door, sand filters).
- **Worlds without air:** every window a porthole, every door an airlock (hazard frame, hatch, green status light);
  domes and pressure halls more often.
- **The other things in the street, sci-fi too:** the wooden power pole is a steel power mast with its energy line,
  the striped canvas awnings over the shops are plated canopies lit underneath, market stalls have a metal counter
  and a holo sign, the signpost is a pylon of lit arrow plates, the lookout tower steel with a glazed cab, the fish
  farms' walkway steel grating on pontoons, the practice targets project rings of light.
- Smoke test: every settlement building is one of the sci-fi architectures, sealed exactly on airless worlds, and
  every architecture paints (sealed and not).

## alpha 0.7.51.5 – 2026-11-10

**Debug functions for packages 49–51** (F12 → new tab **Ground**) – every package brings its debug functions
(Leitlinien 1.5); these were missing for walking, landing, cities, settlements, gear and the clinic.
- **Status line:** where you are on foot (place, level, the world outside, daylight), docked at, health, energy,
  oxygen, ammunition, the suit.
- **On foot (49, 50):** open the deck of the docked station (in a city its hangar); straight to a level – hangar or
  commercial level on a station, hangar, shopping street or tower bar in a city.
- **Landing (50):** descend at once to any body of the system (the planet map opens); land straight at a city,
  outpost, mine, research camp or landing field – optionally seeing the body as another world type, with a
  settlement's economy forced, at a chosen hour. If the body has no such place, a debug place is added (not saved).
  Set the time of day where you are (day, dusk, night, dawn) – every world turns on with it.
- **Gear, the world outside, the clinic (51):** any piece by family and quality (F–A) into the pockets, fill the belt,
  refill the suit, empty the pockets; set health, energy, oxygen or ammunition to a percentage; **suit invulnerable**
  (the world outside does not hurt – energy and oxygen still drain); force the world outside on the current map
  (any world type, or back to the place's own); collapse now; wake in the clinic of the station or city you are
  docked at.
- The debug menu keeps itself inside the screen (seven tabs, narrower tab buttons).
- Smoke test: a check for all the new debug commands; `--only=debug_shot` (windowed) saves a picture of the tab.

## alpha 0.7.51.4 – 2026-11-10

**The clinic, and where you wake (Luz).** Package 51 is complete.
- **The Clinic (Mercy Hall)** is a real room on every station's commercial level and in every city's shopping
  street – two beds with their monitors along the wall; treatment heals what is hurt (paid by what is missing).
  Settlements have none.
- **Ship lost:** after the buy-back window you wake in the clinic of the last station you docked at.
- **Fallen on foot:** you wake in the clinic of the nearest city in the system (your ship is taken to its hangar) –
  if there is none, at the last station (the ship with you). What was in your pockets is gone; you come to weak.
- A codex entry on suits and personal gear.

## alpha 0.7.51.3 – 2026-11-10

**The world outside: energy, oxygen, what gets through.**
- **Each kind of world has its air and its hazards:** terran, ocean and jungle worlds good to breathe; deserts hot;
  ice worlds cold and thin; lava worlds hot and toxic; metal worlds toxic; rocks, dwarfs and most moons airless
  and cold; icy moons bitterly cold; volcanic moons hot, toxic, almost airless.
- **Outside** (landing fields and settlements – not under a roof, not in a city or on a station) **the suit works:**
  its life support keeps out what it can and draws energy for it; what gets through (by the suit's protection)
  hurts; where the air cannot be breathed the oxygen tank empties – empty, you suffocate. The shield generator draws
  energy all the time, the sprint booster while running. If the energy runs out, the life support stops.
- **The helmet goes on** where the air is not to be breathed or poisoned – and the townsfolk and guards out there
  wear suits and helmets too.
- **On foot, the suit's bars:** health, shield, energy, oxygen (where it is used), ammunition; the hazards and how
  much of each gets through; the belt along the bottom, its places on the **number keys** – medkits, stimulants
  (quicker for 20 s), energy cells, oxygen cartridges and the new **ammunition boxes** work; warnings when energy,
  air or health run low.
- **Charging points** by every landing pad (the fuel points) fill the suit's energy and oxygen; back aboard, the
  ship charges the suit and the medbay sees to you.
- The suit's weight and plates slow you, a stimulant and a sprint booster speed you up.
- If your body gives out outside, for now the landing drone's autopilot carries you back up (the clinic follows).

## alpha 0.7.51.2 – 2026-11-10

**The Gear shop, and the pilot in the suit.**
- **Gear (Fieldkit Outfitters)** – the personal outfitter: a walk-in shop on the stations' commercial level, in the
  cities' shopping streets and in every settlement (the settlements' street grew a shop longer). Suits, weapons,
  features and tools by family, a button per quality with its price; grenades and consumables; sell what is in
  your pockets for half the price. What you buy goes into your pockets.
- **What a shop carries follows the place:** the best quality as the ship outfitter's (C at small places, B and A at
  bigger stations, in high-tech and rich systems, A in military ones); combat suits and heavy weapons in military
  systems and at the bigger stations; a settlement sells the plain things (civilian, work and survey suits,
  sidearms, tools, consumables – war gear only in military systems).
- **The pilot walks about in the suit:** its colours, plates on a combat suit, the life-support pack on the back,
  the straps over the shoulders; the first weapon slung across the back (a laser glowing); a helmet with its glass
  dome is ready for 0.7.51.3 (outside on worlds whose air is not to be breathed). A new suit shows at once.

## alpha 0.7.51.1 – 2026-11-10

**Package 51 begins: personal equipment (Luz: the suit like a ship).**
- **The suit is the pilot's hull:** its class sets how many weapon slots, belt places and feature slots there are
  and how well it keeps out heat, cold, toxic air and vacuum – the **Civilian Spacesuit** (1 weapon · 2 belt ·
  1 feature), the **Survey Suit** (1 · 3 · 2, the best life support), the **Work Suit** (1 · 4 · 1, plated), the
  **Light Combat Suit** (2 · 3 · 2, quick, a strong shield) and the **Heavy Combat Suit** (3 · 2 · 3, heavy plate, a
  deep magazine – slow and short of air). Quality F–A gives a better base shield, more ammunition, more armour,
  more energy and oxygen.
- **Every suit has energy** (shields, tools and the life support will draw on it) **and an oxygen tank.**
- **Weapons F–A, no sizes:** optical (laser pistol, laser rifle, cutting beam – strong against shields, on the suit's
  energy), kinetic (slug pistol, burst gun, rail carbine, scatter gun, long rail – strong against armour, on
  ammunition), explosive (grenade launcher – strong against the body, bursts). Shooting comes with package 52.
- **The belt:** frag, EMP, smoke and **shield grenades** (a dome of shield that turns fire from outside and lets
  yours out), tools F–A (scanner, cutting torch, mining laser), medkits, stimulants, energy cells, oxygen cartridges
  – stacked, on the number keys.
- **Features** (the suit's modules): shield generator, armour plates, sprint booster, jump jets, temperature
  regulator, oxygen reserve, ammunition pack, battery pack.
- **Pockets** (12 places) and **a locker in every ship** (12 / 20 / 30 places by the ship's size), at hand aboard and
  in the hangar beside her.
- **The pilot window has a Gear tab:** the suit and what it adds up to (health, shield, armour, energy, oxygen,
  ammunition, speed, protection), its slots, the pockets and the locker – click to put on, take off, store, fetch;
  point at a piece for what it does. A suit change puts what no longer fits into the pockets.
- New pilots start in a civilian suit (F) with a laser pistol, two medkits and an energy cell.

## alpha 0.7.50.17 – 2026-11-10

**The small places from the air (Luz: "far too big – small lights like the cities, with what marks them, bound to
the land").**
- **Settlements in the flight down are small now and drawn like the cities:** a short street of houses (roofs by
  day, lit windows by night, now and then one going dark), its lamps, the way to its four pads with their blinking
  lights – and beside it **what it lives from**: an open pit with its terraces and the lights of the haul trucks
  going round, fields in their colours with their rows (glowing greenhouses where nothing grows outside), halls with
  smoking stacks and a red light on top, a tank farm with its flare, a dish array with its beacons, a training yard
  with a vehicle crossing it, gardens. Fish pens out on the water where the sea is near.
- **Bound to the land:** houses, roads and the economy area only on land (the area goes towards the land and away
  from the pads), the pens only on the sea.
- Ruins and crash sites small and dark too (scattered walls; the furrow the wreck ploughed, a fire on it).
- **Night lies over the land** in the flight to a city or a settlement at night.
- **No engine flame on the way down** – neither in space nor in the flight (Luz); on the way up it stays.

## alpha 0.7.50.16 – 2026-11-10

**The way down and the sizes (Luz: "the flame far too big", "the shuttle gigantic next to the Threshold").**
- **The descent's flame keeps to the ship's size** – it shrinks with her as she sinks (it used to stay as big as
  the heat round her). Drawn new: its glow, a rounded flame in four layers, the white-hot core, shock diamonds.
- **The heat of the way down, drawn new and in more detail:** a bow shock shaped round her nose in three layers
  (white-hot at the stagnation point, orange, a dim red edge), flickering at its rim; a plasma wake streaming back
  from it, swaying and thinning out, turbulent bands in it; streaks flowing over the shell; sparks of the ablating
  hull shed behind her; a soft glow of ionised air round it all – added light, so it glows.
- **The landing drone and the ship to their real sizes:** the drone (~10 m) beside the ship by her real length –
  next to a scout it is a third of her, next to a Threshold (124 m) a speck under her belly. For the catch the view
  comes in close: the drone big enough to see, a big ship filling the sky over it; she flies higher on the screen,
  the drone climbs up to her from below. Her flame starts at her tail, as big as she is.
- The 2D anti-aliasing setting is gone (the Compatibility renderer does not support it – Godot warned about it on
  every start).

## alpha 0.7.50.15 – 2026-11-10

**Taking off, the landing drone, the pads (Luz, after playing).**
- **Taking off asks where to:** at the drone's ramp (or the stairs to your ship in a city's hangar) a small panel –
  **1. back to orbit** or **2. to the planet map** to pick another place on the same world, without the climb to
  orbit and the way down again.
- **The landing drone is a dropship now:** a fuselage for four (four portholes along its side) with the vehicle bay
  aft under a roof hatch, the cockpit canopy wrapped round its nose, four ducted lift fans on stub wings, two
  thrusters at the tail, a dorsal spine with a sensor housing and a mast, red and green nav lights, a band in the
  line's colour – about 8 m long, as big as it must be for four people and a vehicle.
- **Its ramp is animated:** after the touchdown the side door slides up (the lit cabin behind – seats, the rover's
  flank) and the ramp folds down on its struts, its rail lights running; you walk down it. Going back you walk up
  it, it folds up behind you, then the drone lifts off. The other drones on the pads lower and raise theirs too.
- **The drone is caught by the ship:** back up by the drone, it climbs off the pad while the ground falls away
  below, the clouds close in, the ship comes down over it out of the sky, takes it up into her bay on a tractor
  beam – a flash as the clamps close – and pulls away. Then orbit or the planet map.
- **The landing pads in detail** (and bigger, for the new drone): slabs each a little their own with seams, cracks
  and stains, the scorch of the lift-offs round the middle, the touchdown ring with its H, a hazard band round the
  edge with a white line inside, corner brackets, the pad's number painted big, edge lights in their housings,
  drainage grates, tie-down rings, a fuel hatch; a fuel point by each pad, a hover cargo loader on the apron.
- **The pads' lights live:** dim and steady while a pad is clear, a running chase towards it while a drone comes
  in (outwards while one lifts off), cyan while one stands on it – and beside each PAD sign its status: CLEAR,
  INBOUND, DEPARTING, OCCUPIED, YOUR DRONE.
- The settlements' landing field: two pads north of the street, two south of it, the street running out between
  them; the town begins east of it.
- The hint under the title fits the place (no more "the stairs in the hangar" in a settlement).

## alpha 0.7.50.14 – 2026-11-10

**Settlements in the future (Luz: "the vehicles look very 21st century – make them sci-fi").**
- **The machines, new:** the **ore hauler** runs on two armoured track pods with glowing seams between their plates,
  a chamfered hexagonal hopper with hazard chevrons and a light line, heat vents glowing along its spine, a canopy dome
  with a glowing visor band, a sensor mast (crystals glinting in its ore when loaded); the **mining platform** floats
  on three anti-grav pads with a glowing reactor behind its vents – its articulated arm with glowing joints and a
  light line, a **cutter claw** with a plasma edge; the **harvester glider** hovers on its glowing skirt with an
  intake rotor and a cutter bar of light; a **hover tanker** on skids with a capsule tank and glowing ports; a **hover
  tank** with a twin-barrelled turret in its energy coil; a **hydrofoil** work boat with its jets.
- Whatever floats bobs gently and lights the ground below it.
- **The plants:** exhaust towers with plated rings and light between them and a hot vent on top, tanks with a light
  band and status lights, dishes with a glowing emitter, the rig's derrick with an energy core, fence posts with
  lights, the parked armoured vehicles and rovers on hover skirts and skids.
- **The buildings:** a light strip under the eaves of the prefab halls, modules, quonsets and containers, and a lit
  access panel beside every door.

## alpha 0.7.50.13 – 2026-11-10

**Settlements to scale (Luz: "the sizes are all off").**
- One scale for everything in the settlements, set by the people (about 15 art px a metre): a storey ~2.6 m, doors
  2 m high, windows about a metre, street lamps ~4 m, trees 7–10 m, a container 12 m long and 2.6 m high.
- **Buildings** grew to it: taller fronts, bigger doors with glass and canopies, windows with transoms, curtains and
  now and then someone inside, shutters with slats, stone windows as tall pointed arches, wider houses; containers,
  domes (portholes, an airlock as big as a door) and quonsets to match.
- **The machines are drawn new, at their real size** (pixel pictures with wheels, cabs, ladders, beacons):
  a **haul truck** with tyres taller than a person, the **excavator** with its boom, stick and bucket, a **combine
  harvester** with its turning reel, a **tanker**, an eight-wheeled **armoured vehicle**, a **work boat**.
- **The mine is seen from its rim** (as Luz suggested): the berm with its marker posts, then the pit falls away –
  rock faces with their strata, benches with tyre tracks and safety berms, the haul road cut down across the faces;
  a haul truck on the first bench, the excavator loading another on the next, a third far down – the deeper, the more
  in the haze.
- The other areas to scale: 12 m containers two high under a ten-metre gantry crane carrying one, chimneys 13–15 m,
  great tanks with stairs winding up, big dishes with ribs and their feed, armoured vehicles, a lookout tower,
  silos; the trees at the bottom edge stay low (no longer hiding the shops).

## alpha 0.7.50.12 – 2026-11-10

**Settlements: what the place lives from, around it.**
- East of every settlement, behind a fence where the street ends (a lookout with a railing, a sign), lies its
  **economy area** – alive:
  - **Mining:** an **open pit** stepping down in terraces (strata in their faces, a pool at the bottom), the ramp
    winding into it; a big **excavator** at the bottom swinging its arm, **haul trucks** winding up and down the ramp
    (loaded on the way up, dust behind them), a **conveyor** running to the ore heaps, the headframe.
  - **Farming:** **fields** of different crops (golden grain, green, dark green, purple) with an irrigation channel and
    silos; a **harvester** working its rows (the cut rows behind it), **crop drones** spraying. Where nothing grows
    outside (ice, rock, lava, toxic worlds, airless moons): **hydroponics** – rows of greenhouses and domes.
  - **Industry:** halls with smoking **chimneys**, a pipe run, rows of stacked **containers** under a **gantry crane**
    moving a container along its rails, pallets and barrels, a truck on its round.
  - **Refinery / chemistry:** a **tank farm** with pipe runs between the tanks and a **flare** burning.
  - **Research / high tech:** a **dish array** with cables between the dishes, a control building, a rover, and a
    **launch pad** – now and then a rocket goes up (the countdown lights, flame and smoke).
  - **Military:** a **training yard** with targets, parked armoured vehicles, one on its round, a patrol drone.
  - **Tourism:** **gardens** with trees, palms, flower beds, a fountain, a lookout tower, birds.
  - **On ocean worlds:** **fish pens** floating on the sea with a boardwalk between them and a boat going round – or
    an **offshore rig** on its platform with its flare.

## alpha 0.7.50.11 – 2026-11-10

**Settlements in detail – every building its own (Luz: "too chibi, too boxy").**
- **Eight architectures**, each building drawn on its own (roof from above, front below, its own seed): **prefab**
  halls under corrugated metal (ridges, rivets, rust streaks, a canopy over the door, pipes, a neon sign), **stacked
  containers** in different colours with a ladder, **quonset** halls (a ribbed half-barrel roof, the door in the end
  wall), **habitat domes** in rings with portholes and an airlock in hazard stripes, **gabled houses** with tiled roofs
  (moss on the tiles), plastered or planked walls, shutters and flower boxes, **adobe** with a parapet, rounded
  corners, deep windows, an arched door and a canvas awning, **stone houses** with slate roofs and gold-lit
  pointed-arch windows, and white **modules** with a long window band and a light strip.
- Which one by the power that built it (independent: prefab, containers, quonsets; Assembly: gabled houses, domes;
  Covenant: stone; Directorate: modules, domes) and by the world (adobe in the desert, domes and quonsets on ice,
  rock and lava worlds); one or two storeys, each its own colours.
- **On the roofs:** air units with fans, water tanks, solar panels, antennas with their lights, small dishes, vents
  and skylights, planters, laundry lines. **On the walls:** windows with frames, sills and curtains, the sky in the
  dark ones, meter boxes, pipes, lamps over the doors, steps, grime along the foot.
- **Two rows of houses** now, the special building with two storeys; between them market stalls with striped
  awnings and goods, power poles, crates and barrels, undergrowth; a parked rover by the pads, a signpost.
- **The world's edge in detail:** trees of several kinds and sizes (broad crowns of many clumps with vines and
  flowers in the jungle, conifers in the woods, palms), ferns and bushes with berries in the gaps; groups of boulders
  with facets and cracks (moss on toxic worlds, glowing seams on lava worlds); dunes with rocks; on ice worlds
  snowdrifts, ice shards of every height and snowy rocks.
- The shops along the street each have their own striped awning; the prompt on foot has a dark outline (readable on
  snow and sand).

## alpha 0.7.50.10 – 2026-11-10

**Settlements – the small places come alive.**
- Outposts, mines and research camps are now **settlements under the open sky**, one walkable map: your landing drone
  comes down on one of its **four landing pads** – on the others, other landing drones come and go (dropping in from
  above with their shadows closing in, setting down in a puff of dust, waiting, lifting off), their beacons blinking.
- **The street** runs from the pads past the settlement: its **shops** on the south side – walk in, as on a station
  (market, outfitter, bar, repair bay, bulletin board, news, as the place has them) – houses on the north side with
  lit windows, lamp posts, crates, the fuel pump by the pads.
- **The building it is known for**, by what it lives from (a mine always mines, a research camp researches, an
  outpost lives from its system's economy): an ore depot with its headframe, ore cart and spoil (mining), an agri
  co-op with greenhouses and a silo, a workshop, a refinery outlet or chem plant with its silos, a tech lab or
  research station with its dish, a recruitment office with banners (signs on crew), a lookout hotel.
- **What bounds it is its world:** dense jungle on jungle worlds, woods on terran ones, **the sea round its platforms**
  on ocean worlds (a gangway between them, buoys blinking), dunes in the desert, ice shards on ice worlds, a crater's
  rocks on barren worlds and moons, cooled lava glowing on lava worlds.
- Guards walk their rounds (one posted by your drone), its people go about; a settlement works like a station (its
  own market, by the kind of place); in its power's colours; day and night as in the cities.
- Ruins and crash sites stay landing fields for now – they become POIs (package 53).
- Codex: **Settlements**.

## alpha 0.7.50.9 – 2026-11-10

**City guards.**
- Guards stand in the cities now – posted by the lifts and the stairs to your ship, others walking their rounds
  through the hangar, the shopping street and the tower bar; more of them the safer the system. They wear their
  power's uniform (contract security in a free city, the Assembly's militia in navy and white, the Covenant's Wardens
  of the Road in crimson and gold, the Directorate's civic order in white and green), an armoured suit and a visor,
  a rifle slung across the chest and a lamp blinking on the shoulder.
- Walk up to one and speak to them ([E]) – they have a word for you, in their power's way. Weapons stay holstered in
  the city.
- The hangar flags carry their power's sign: the Assembly's ring, the Covenant's sun road, the Directorate's compass.

## alpha 0.7.50.8 – 2026-11-10

**Sunset from the tower bar – the day goes on while you are in the city.**
- The time of day in a city now goes on while you walk in it (before, it was fixed when you came down): the sky
  outside, the street's light and the light falling through the bar's glass follow the sun as it goes round.
- **Dusk and dawn:** the sky turns to the colour of the star's setting light (a red dwarf's deep red, a blue star's
  violet, a yellow sun's orange), the towers glow in it, the sun sinks low and big behind the towers in the west (or
  rises in the east), the light through the bar's window turns to sunset, and the windows of the city come on one by
  one – the red lights on the tops start blinking, the neon brightens. At dawn the other way round.
- The street: its light warms at dusk and darkens into night (the lamps and neon taking over), and brightens at
  dawn.

## alpha 0.7.50.7 – 2026-11-10

**Cities: a ground plan for every kind of world, the worlds turn, bar and hangar in the city's style.**
- **Ground plans from the air:** a city's form now follows its world – on terran worlds it spreads out round its
  heart; on **ocean worlds** it crowds along the coast with piers reaching out into the sea and platforms floating on
  it; in the **jungle** (and on lava worlds) its quarters lie in clearings, roads running between them; in the
  **desert** it is a dense square behind its wall with an oasis inside; on **ice and toxic worlds** its quarters sit
  under domes linked by tubes; on **barren worlds and rocky moons** it stands on a crater's rim and in its middle;
  metal worlds are a grid. And its streets follow who built it: crooked avenues (independent), ring roads and parks
  (Assembly), spokes to a great cathedral square (Covenant), a strict grid (Directorate). By night its lights, by day
  its roofs, parks and streets – always only on land (piers and platforms only on the sea).
- **The worlds turn:** the sun goes round every world – a day lasts 20 to 40 minutes of play, each world its own
  length and hour – so the same city can be visited by day and by night. The planet map shows where the sun stands
  now (the night side dark, the cities there glowing) and says for each city "Day there now · sunset in about N min"
  or "Night there now · sunrise in about N min".
- **The bar and the hangar in the city's style:** the decks take the power's colours and the bar its furnishing –
  a neon lounge (independent), a garden bar with planters (Assembly), long tables on red carpet with banners
  (Covenant), a bright cafe with holo pillars (Directorate); the hangar hangs its power's flags on its walls (blue with
  the white hand, red with the gold sign, green and white – neon posters in a free city).

## alpha 0.7.50.6 – 2026-11-10

**The cities refined: four building styles, day and night, a street canyon, a city that stands up.**
- **Four styles – who built the city:** **independent** cities are the cyberpunk sprawl (dark crowded towers, neon of
  every colour, antennas, fire escapes, paper lanterns over the street); the **Assembly** builds light stone and glass
  with domes, terraces and roof gardens, green balconies, warm windows and strings of bulbs; the **Covenant** builds
  dark red-brown stone with pointed spires and pinnacles, narrow gold-lit windows under pointed arches, long red
  banners with the gold sign and pennants over the street; the **Directorate** builds white towers on a strict grid
  with chamfered hexagonal crowns, solar roofs, whole floors of cool white light and green light bands. The street's
  made-up shop fronts follow the style too (co-op market and voting booth; chapel, reliquary and pilgrim hostel;
  institute, exam hall and data cafe …).
- **Day and night:** every city lies on the day or the night side of its world – where the planet map shows it –
  and keeps it: the flight down, the landing hatch, the street and the view from the tower bar are lit by day (sun,
  clouds, glass catching the sky, the street bright, the neon faint, sunlight falling into the bar) or by night (lit
  windows, glowing neon, red lights blinking on the tops, the street dark under its lamps).
- **The street canyon:** the shopping street is no longer a room – above the shop fronts the buildings rise into the
  sky, storey on storey of windows, balconies, fire escapes, air units, signs and banners, a strip of sky at the top
  with speeders crossing it, strings of lights hanging along the street.
- **The landing hatch's city stands up:** towers seen a little from the south – their fronts with floors of windows,
  their roofs in the style's way (domes and roof gardens, ridged roofs with spires, hexagonal roofs with solar panels,
  air units and flyer pads), their shadows on the ground by day.
- **The flight down:** the city now lies on the ground and comes with it (no longer faster than the ground), always
  on land – its lights (by night) or its roofs (by day) only where there is land, never on the sea; the dark rings
  round it are gone.
- The tower bar's window front is square in a city (no space-station corners); the title on foot has a dark plate.

## alpha 0.7.50.5 – 2026-11-10

**Package 50b begins: the cities – down through a landing hatch, into the city's hangars, its shopping street and
the bar high up in its towers.**
- **The landing hatch:** most ships are far too big for a city's streets, so a city takes them in below the ground.
  Seen from above – the roofs of the city at night all round (towers with air units, roof gardens, flyer pads, neon
  edges, blinking warning lights; streets with their lamps and cars) – your ship comes down over a giant hatch with
  hazard stripes; its lamps blink amber, its two leaves slide apart, the shaft below shows frames of light running down
  into the deep; she sinks into it, darker and smaller, and the hatch closes over her (lamps green while it is open).
- **A city works like a station:** it has its own market, outfitter, shipyard, bonds, bar with crew to hire, news and
  bulletin board – its kind follows the world it stands on (trade cities on terran and ocean worlds, industry on
  deserts and lava worlds, ice refineries on ice, mining towns on barren rock, research on toxic worlds …).
- **The city's hangar:** you arrive beside your ship, as on a station (the hangar and shipyard shops on its walkway).
- **The lifts:** Hangar · Shopping street · Tower bar.
- **The shopping street:** busy – the real shops on its south side, on its north side a row of made-up shop fronts
  (noodle bar, cyberware, karaoke, tea house, pawn, hotel …) with lit windows, striped awnings and neon names, lamp
  posts, vending machines and plants between them.
- **The tower bar:** the bar high up in the city's towers (its floor on the title) – out of its window front the city
  at night: towers far and near with their lit windows, neon running down them and red lights blinking on their tops,
  speeders in their lanes with light trails, drones drifting past; the layers move at their own pace as you walk.
- **Leaving:** down the stairs to your ship – the hatch opens, she rises out of the shaft, it closes under her and she
  climbs back to orbit.
- Codex: **Cities**.

## alpha 0.7.50.4 – 2026-11-10

**Cities as lights, and a landing drone for the small places.**
- **Into a city:** no more drawn blocks – the city comes up out of the dusk as its lights: fine strings of light
  along its avenues, hundreds of tiny warm windows, densest and brightest in its heart, now and then one going out.
  Your ship sinks into them, growing smaller and smaller until she is a speck among the lights.
- **The landing drone:** every ship carries one. Small places (outposts, mines, ruins, wrecks, camps) are not landed
  at by the ship herself: halfway down the drone bay flashes, the small lander drops out of it with its own flame,
  your ship pulls up and away, and you follow the drone down. It sets down on the pad in its cloud of dust; to get
  back up you board the landing drone, which flies you back to your ship.

## alpha 0.7.50.3 – 2026-11-10

**The landing gets its way down – no more hard cuts.**
- **Into the planet:** as the ship sinks, the camera follows her down (zooms in); at the end the heat flares into a
  white flash that turns to black (on airless moons just black), and out of the black the planet map fades in – the
  planet turning into place, its places lighting up one after the other with a little flash, then the list.
- **The flight down (seen from above):** after picking a place you fly down to it – the planet's own ground passes
  below (seas and coasts and continents, dunes, ice, glowing lava cracks, craters – in its colours) and comes closer,
  your ship's shadow closes in on her, clouds drift between you and the ground where there is air, the last of the
  entry heat fades, the engine burns; at the end the place itself comes into view on its patch of land – the blocks
  and lit windows of a city, the domes of an outpost or camp, a pit mine, ruins, a wreck with its scorch mark – and
  its landing pad, its lights blinking, slides under you.
- **Touchdown:** the ship comes down onto the pad from above – big at first, near to you, her shadow meeting her –
  sets down in a cloud of dust (in the ground's colour) with a jolt, and you walk down her ramp.
- **Lift-off:** up the ramp, dust, the ship rises off the pad, bigger, and is gone upwards; a white flash, and she
  climbs out of the planet into orbit while the camera pulls back.

## alpha 0.7.50.2 – 2026-11-10

- **Fix – no way down at the beacon:** a selected descent beacon now has a **Descend** button (also the dock key);
  the ship flies to the beacon – warping first if it is far – and goes down. Before, only *Warp to* and *Approach*
  were offered.

## alpha 0.7.50.1 – 2026-11-10

**Teil 7, package 50 begins: down to the planets.**
- **Descent beacons:** over the middle of every planet and moon with solid ground (not the gas giants) hangs a descent
  beacon – a small probe with three blinking arms and rings pulsing out from it; from there the planet below looks
  its biggest. It is in the overview (▼) and a warp target; click it, and the ship flies there and goes down.
- **The way down:** the ship speeds up along its heading, flame bright, then sinks – smaller and smaller – into the
  world below. On worlds with an atmosphere it glows: a bow shock of heat in front of it, plasma streaming past, a
  glowing ball sinking away. On airless moons it just drops, cold and quiet.
- **The planet map:** below, the planet fills the screen, its places marked on its face – cities (on worlds people
  like, more where the night side glitters), outposts, mines, ruins, crash sites, research camps – and listed beside
  it with a word about each. Pick one and land, or go back to orbit.
- **Landing:** you stand on the landing field at the place: the planet's own ground all round, a concrete pad with
  your ship on it, her ramp down, lights along the pad, fuel and crates, and a gravel path to the place itself. Walk
  up the ramp and the ship climbs back to orbit – out of the planet, small and glowing, growing, on its way.
- While you are down, your ship counts as docked (safe, hidden); a game saved on the ground opens the planet map
  again. The cities themselves – streets, shops, people – come with the next update.
- Codex: Landing on planets.

## alpha 0.7.49.14 – 2026-11-10

- **A look at your ship:** sit down on the bench in the hangar and the camera glides over to your ship and centres
  it; stand up and it glides back to you.
- **The view from the bar:** the star and the planet the station circles now always stand in the part of the window
  front you can see – whatever the screen size and wherever you stand – as things far away do.
- The camera on the deck eases now instead of jumping.

## alpha 0.7.49.13 – 2026-11-09

**The bar works, the station window stays shut on foot, every ship its own hangar.**
- **At the bar:** sit down on a bar stool (or E at the counter) and the bartender talks to you: *A drink, please*
  (Nebula Ale, Pulsar Punch, Void Whisky, Orbital Cola – a few credits; the glass goes up to your mouth; alcohol is
  noted for a debuff to come and wears off with time), *What's new?* (funny, useful or nonsensical bar talk) and
  *Who's looking for work here?* (the crew window). The bartender has a name.
- **On foot, no way back into the station window:** a service opened from the deck shows only that service – its
  button says *‹ Back to the deck*, closing it puts you back on your feet; the station hotkey does nothing while you
  walk.
- **Ship swap:** every ship has its own hangar number at a station. Board another ship at the hangar service and,
  leaving the shop, you are told where it stands ("Your active ship, the …, stands in Hangar 07 – the lift takes
  you there"); the lift offers that hangar, the old ship's hangar is no longer a way aboard (its stairs tell you
  where to go).
- **The hangar bench** stands by the glass and faces the ship – no longer in front of a shop's door.
- Talks and panels on the deck are drawn above the neon signs.
- Roadmap: **minigames** noted as a package of their own (54b – billiards at the dive's pool table first).

## alpha 0.7.49.12 – 2026-11-09

**Seats sized for the new figures.** Every piece of furniture you can sit on is rebuilt to the tall figures: the seat
at hip height, the backrest up to the shoulders – chairs (backrest on the side away from the table), bar stools (a
foot ring), benches, the sofa (cushions, arms), crates, sun loungers. Benches whose sitters turn their backs to you
(the far side of the long tables) now have their backrest in front of them – a rail at the small of the back, the
sitters' shoulders and heads above it – instead of none.

## alpha 0.7.49.11 – 2026-11-09

**New figures on foot (Luz's choice "C3").** The little chibis are gone: people are now tall and slim – about six
heads, 18 × 40 px, drawn finer than the deck (2 screen px per pixel), so they stand about as tall as before and fit
the doors and furniture. Black outlines and a **neon rim light** – cyan from the left, pink from the right, as if the
station's signs lit them. Broad shoulders, a narrower waist, arms with elbows and hands, a face with eyes, brows, nose
and mouth, boots with a shine; the jacket open over the shirt, the flight suit with its zip and a chest light, the
coat's tails, the armour's shoulder plates; every hair style, beard and headgear of the portrait. Front, back and
side, two walking steps (legs and arms swing), and a sitting pose with bent legs.

## alpha 0.7.49.10 – 2026-11-09

**Life down in the hangar bay** – roughly to scale, tiny next to the ship:
- **Loaders** – little yellow forklifts – drive between the crate stacks along the bay's walls and the ship, a crate
  on their forks on the way there, empty on the way back, a light blinking.
- **Repair drones** fly to spots on the hull, hover there and weld – sparks falling.
- A **fuel truck** stands at the stern, its hose to the ship, fuel pulsing along it.

## alpha 0.7.49.9 – 2026-11-09

**The hangar feels far below – and gets its own shops.**
- **No people down in the bay:** the mechanics and the person-sized crates, barrels and machines are gone; ships are
  giants, and the bay is far below the walkway. Its floor has small plates now, tiny crates and carts line its walls,
  little lights its edges, and a haze lies over it – thicker towards the far wall –, the ship in it too.
- **Hangar and shipyard on the walkway:** where the station has them, the **Hangar** service and the **Shipyard** are
  shops on the south side of the hangar walkway (door, neon sign, counter, keeper) – no longer up on the commercial
  level.

## alpha 0.7.49.8 – 2026-11-09

**The hangar, levels with a lift, and the waystations' own deck.**
- **The hangar:** getting out of the ship you now stand in the hangar – on a raised walkway along a glass front, and
  below it, in the closed bay, **your own ship** (nose to the bay doors' side, its shadow on the floor, landing marks,
  crates, a machine, mechanics, lamps). The walkway is as long as your ship needs. At the west end the **stairs**
  lead down to the ship – you start there, and E there takes you back aboard and to the station window. At the east
  end are the **lifts**.
- **Lifts with a choice:** E at a lift opens a little panel: *Hangar* or *Commercial level* (1 / 2, the level you are
  on is marked). You step in, the doors close, and you come out of the lift on the other level, the doors opening.
  The commercial level is the deck built so far (shops, corridor, bar); its lifts work the same.
- **Waystations** have a deck of their own: instead of the wide bar a round **glass dome** out front, completely
  rounded, and under it a **diner** – checkered floor, a long counter with the cook behind it and red stools, booths
  in the corners, the jukebox under the glass, a neon *Diner · open 24/7* over the door; in the corridor vending
  machines and lamps.

## alpha 0.7.49.7 – 2026-11-09

**Every station type its own deck, people who find their way, sitting properly, conversations after Luz's mockup.**
- **Station themes** – the bar, its floor, the window's corners and what stands about follow the station type:
  - *Trade hubs:* the lounge – round tables, a sofa, a rug, plants along the window.
  - *Military outposts:* a mess hall – long tables with benches, steel deck plates, banners and lockers, almost
    square window corners.
  - *Research stations:* a bright café – little tables for two, white tiles, holo pillars, specimen tanks.
  - *Industrial complexes and shipyards:* a canteen – long tables, grating or deck plates, pipes, vending machines,
    engine parts on display.
  - *Mining colonies and pirate havens:* a dive – a pool table, barrels for tables, crates to sit on, worn dark
    planks, ore carts, barrels, cages and rubbish in the corridor.
  - *Agri stations:* picnic tables among planters full of crops, flower beds.
  - *Ice refineries:* the lounge in icy tiles with ice sculptures and glowing heaters.
  - *Resorts:* a **beach bar** – sand, a pool in the middle, sun loungers under parasols, palms, little tables for
    two, a fountain and flower beds in the corridor.
- **Sitting properly:** chairs stand at the tables (the backrest away from the table); whoever sits – a guest or you
  – sits *on* the seat with the legs bent, no longer sinking into the floor in front of it. Benches at the long
  tables, crates in the dive and sun loungers can be sat on too.
- **Finding the way:** people walk along paths round walls and furniture (A* over the deck) instead of bumping into
  walls, and now and then go shopping – into the shops, up to the counter.
- **Conversations (Luz's mockup):** talking to someone at the bar opens a conversation screen – the one you talk to
  large in a frame on the left, what they say typed out in the box along the bottom, your answers in a box above it
  on the right (1–9 or click; E / Space shows the whole line). For now: **Info** (opens the questions, the record and
  signing on, as before) and **Goodbye**. The screen is meant for all conversations to come (Teil 8).

## alpha 0.7.49.6 – 2026-11-09

**On the deck: talk to the crew, sit down, the jukebox, lifts with doors.**
- **Talking to the crew:** E at someone with a "!" in the bar starts a conversation with just them – their portrait
  and how they greet you (a rookie is nervous, an elite knows their worth). Ask *What do you do on a ship?*, *How
  good are you?* (bonus, quality, what they learn from, their perk), *What would you cost?* (price and share of
  income) and *Show me your record* (the full crew card), then sign them on – into the station's crew quarters or
  straight onto your ship. Once hired, they pick up their bag and head for the lift. Esc ends the talk.
- **Sit down:** every free chair, bar stool, the sofa and the lobby bench – E to sit, E or a step to get up.
- **The jukebox** plays: three lounge tracks (Neon Rain, Dock Nine Blues, Low Orbit Lounge), E for the next one,
  after the last it falls silent. The music is made in the game, no files.
- **Lifts with doors:** you step out of the lift when you get off the ship; the doors slide open when you come near
  (green lamp) and shut behind you; E at the lift and you walk in, the doors close, and you are back on your ship.
- **Dock office:** the terminals stand along the back wall now, no longer in the doorway.

## alpha 0.7.49.5 – 2026-11-09

**The deck goes a little cyberpunk – neon by default, coloured by the station type.**
- **Neon shop signs:** the shop names are no longer labels but neon signs mounted on the wall over each door –
  glowing tube letters in the shop's colours on a dark plate with brackets, a pool of light below; now and then one
  stutters. Closed shops' signs are dark.
- **The BAR sign** is a tall neon sign: pink tube letters in a cyan neon frame, glowing, one letter flickering now
  and then.
- **Neon and light everywhere:** a neon strip runs along the foot of every wall and its light spills onto the floor
  (in the station type's accent colour); the corridor's guide line glows; lamp posts, the jukebox, the bar counter
  and the tables cast pools of light; the cold light of the planet falls in through the window front.
- **Holographic adverts** hover over the corridor wall between the shops – made-up brands of the cluster (Neuro+,
  Orbital Cola, Synth Noodles, Chrome & Soul …), see-through, with scan lines and the odd jolt.

## alpha 0.7.49.4 – 2026-11-09

**The deck feels closed in now.**
- **Space only through the glass:** everything above the window front's frame is black – the stars, the nebula, the
  star and the planet are seen only through the windows.
- **Even bigger windows:** the window front is seven rows tall, its rounded corners wider; the planet fills it.

## alpha 0.7.49.3 – 2026-11-09

**The deck, second round of Luz's notes.**
- **A real panorama:** the bar's window front is much taller (five rows instead of three) and its two upper corners
  are properly rounded – a curved glass gallery with the star and a bigger planet outside.
- **The lifts sit inside the station:** the lift lobby lies deep in the structure, no longer against open space.
- **The station goes on:** round the deck, to every side and below, the station's structure continues (hull plates,
  seams, vents, small lights) – only above the bar's window front is there space. Walls are one tile thick; the solid
  mass behind them is part of that structure.

## alpha 0.7.49.2 – 2026-11-09

**Package 49 reworked: the deck in a slanted, cosy view, laid out after Luz's sketch.**
- **Slanted view:** walls show their front face, furniture stands up (tables, chairs, sofas, counters, plants, the
  jukebox …) and people walk behind and in front of it, sorted by depth. People are new small figures (big head,
  four directions, walking steps) built from the same look as the portraits – your own pilot looks like the pilot
  you created.
- **The new layout:** you step out of the **lift lobby** on the left (two lift doors, News Archive and Bulletin Board,
  a bench) – the lift takes you back to your ship. It opens onto the **corridor**; below it are the **shops** (Dock
  Office with the ship-service terminals, Market, Outfitter, Shipyard, Bond Office, Image Studio, Refinery,
  Manufacturing … whatever the station offers), each with its door, sign, shelves, counter and keeper. Above the
  corridor, behind a railing, lies **the big bar**: wooden floor, round tables with guests, a sofa, a rug, a jukebox,
  the bar counter with a tall neon "BAR" sign, the bartender and stools.
- **The window front:** the whole north wall of the bar is glass – outside is the system you are in: its nebula, its
  star and the planet the station circles.
- **Crew in the bar:** the people on offer stand in the bar with a "!" over their head – walk up to them and press E
  to talk about hiring them.
- Each station type keeps its own colours (floors, walls, accent lights).

## alpha 0.7.49.1 – 2026-11-09

**Teil 7, package 49: on foot – the ground view and walkable station decks.**
- **Walk the deck:** a new button in the station window gets the pilot out of the ship onto the station's deck – the
  space view keeps running below. Everything still works through the station window as before.
- **The deck:** an **airlock** where your own ship lies docked beyond the window (nose to the hatch, docking tube),
  a **promenade** with kiosks (News Archive, Bulletin Board), planters, benches, pillars and holo adverts, and the
  **shops and the bar as rooms** on both sides, each behind a door with a lit sign in its corporation's colours: Market
  (crates, counter), Outfitter (weapon racks), Shipyard (a ship in the dock window), Bond Office, Image Studio
  (mirror), Refinery/Manufacturing (machines), the Senate, the Curia and the Research Exchange where the station has
  them, and **the Bar** (wooden floor, bar counter with bottles, stools, tables, guests). The ship services (fuel,
  repair, drones, munitions, hangar) are terminals in the **Dock Office**. Only what the station offers gets a door;
  a raided station's shops show "closed".
- **People:** a bartender, shopkeepers, guests at the bar and passers-by strolling the promenade (random looks).
- **Every station type looks its own:** bright and clean on a research station, grey and stern with red lights on a
  military outpost, rust and crates on industry and mining, wood and green on agri stations, icy blue on ice
  refineries, ivory and gold with a fountain at resorts, neon and scrap in pirate havens.
- **Controls:** W A S D (or arrows) to walk, Shift to run, **E** at a door, a terminal or the airlock; the pilot has a
  green ring. A door opens its service window over the deck; closing it is back on the deck; the airlock leads back
  to the ship and the station window. New key group "On foot" (keys may do one thing on foot and another in space).
- Codex: On foot. Smoke tests for the deck (doors reachable, walls, a shop, back to the ship).

## alpha 0.6.75.4 – 2026-11-09

**Fixes from the code review of Teil 6** (`reviews/teil6_review.md`) – all twelve findings.
- **W1 – save size:** the save held every asteroid of every system ever generated (the warmup makes all inhabited ones):
  3.6 MB after 17 minutes, rewritten after every jump. Now only what differs from the generated layout is saved
  (mined or broken rock, colossi dug into, anomalies scanned, salvaged wrecks); untouched systems are left out –
  about 70 KB after loading a new game.
- **W2 – fixed wrecks:** a battlefield hulk or derelict whose loot did not fit into the hold vanished with the rest –
  the Relic of Earth too. Now it stays (salvage again after making room), and things wanted by a contract or a
  blessing come aboard first.
- **M1:** a radiation zone is laid only over fields that stay put (moon fields move with their moon).
- **M2:** a coronal mass ejection no longer sets off the old minefields.
- **M3:** a misjump no longer repairs a battered hull up to 25 %.
- **M4:** planets and moons keep clear of wreck sites, hazards and anomalies when their orbits are rolled.
- **Small:** misjump state cleared on a new game and on loading; the thrust message reads "Not while warping or
  docking."; a fortress garrison has no cowards, and one that fled far away no longer holds the fortress; when the
  polls close only that contract's ballot crates are taken, not other couriers' sealed cargo; the unused price table
  (`Market.sync`) is gone; the arrival animation's timer belongs to the view.

## alpha 0.6.75.3 – 2026-11-09

**Fix: crash when a target died ("Left operand of 'is' is a previously freed instance").** Reported by Luz: attacking
pirates in the Far Reaches with the Citadel and its nine drones, the game crashed as the last pirate went down.
- A lock could still point at a ship destroyed in the same frame (it is cleared on the next tick); drones and modules
  asked for it in between and checked "is it a ship?" on the freed object. `locked_node` now returns nothing then.
- Every place that receives an attacker or shooter (damage, EMP, a ship destroyed or attacked, a fortress garrison
  lost) now treats one that is already gone as "nobody" instead of touching it.
- **Drone shots are quieter and thinned out** (at most one drone shot sound every 0.18 s, −9 dB) – nine drones
  firing pulse lasers sounded like a weapon played a million times.

## alpha 0.6.75.2 – 2026-11-09

**Thrust burst.** Every ship can kick its drives for a moment – **Shift** (rebindable; Shift can be bound now).
- **2.5 s** of **×1.8 top speed** and three times the acceleration; from a standstill the ship shoots straight ahead.
  Costs **a fifth of the capacitor**, then **15 s** to recharge; not in warp, not docked. Works on top of an afterburner.
- A long **yellow-orange flame** behind every drive (about as long as the ship), a flash behind the stern on ignition,
  a short camera shake and a roaring ignition sound (`boost`, placeholder); the flame cools off after the burst.
- HUD: next to the speed – "▶▶ THRUST" while it burns, a recharge bar, "thrust ready [Shift]".
- **NPCs use it rarely:** pirates and patrols now and then when fleeing from an attacker close behind or closing on a
  far target (a 6 % chance every 2 s, 35 s cooldown) – the pilot can still catch up or get away.

## alpha 0.6.75.1 – 2026-11-09

**Interim part 6½, package 75: speed.**
- The **Plasma Drive** had less thrust than an Ion Drive of the same size (1,400 kN at size 5 against 1,843) – now
  2,500 kN at size 5, about 35 % above the Ion Drive (still more power-hungry and less agile).
- **New speed curve:** speed follows the square root of thrust per mass (was linear), set to 300 km/s at 0.2883 kN
  per tonne. Double the thrust is about 41 % faster instead of twice as fast. The standard fits now average about
  **300 km/s** (S 271, M 331, L 297, was S ~250, M ~250, L ~180); with the best engine S ~560, M ~430, L ~325 –
  big ships stay slower at their best, but they all meet in the middle. Small ships with oversized engines no longer
  reach 1,000–1,600 km/s.
- `Balancing_Kernmodule.md`: all core modules by size and quality, how the values scale, the speed formula.

## alpha 0.6.40.10 – 2026-11-09

**Package 40e: codex, debug, tests, balance and performance** – package 40 (the new cluster) is done.
- **Codex:** "The Cluster" and "Security and territory" tell of the new cluster (about 240 systems; the core shared by
  the Assembly and the Covenant, the Directorate's enclave, the Rim, the Far Reaches, the Veil); new entry **The Rim
  and the Far Reaches** (unlocked on entering the Rim).
- **Debug menu – "The new cluster (package 40)":** to the Rim, the Far Reaches, the Veil's edge, a pirate fortress
  (outside its guns), an old battlefield, a pre-Severance derelict, a radiation zone, an ion storm, an old minefield
  (the next one each click); the next jump misjumps; break / rebuild the fortress here; hazard wards (A); Pre-Severance Tech.
- **Balance:** the Far Reaches get one extra asteroid field, not two; Veil rifts hold exotic matter less often
  (40 % instead of 60 %) and give 3–6 Veil readings instead of 4–8; no waystations in the Far Reaches or in fortress
  systems.
- **Performance** (uncapped, 1600 × 900): zoomed out in a Rim system 65 → 157 fps, in the core 111 → 257 fps – the
  radar gathers the objects in its range four times a second instead of walking every asteroid each frame, and rocks
  smaller than about two pixels are no longer drawn; radiation zones 122 → 202 fps and ion storms draw a haze texture
  instead of dozens of big circles; old minefields 208 → 373 fps – old mines look for ships five times a second and
  redraw only on screen. Loading a new game: 13.2 s (as before).

## alpha 0.6.40.9 – 2026-11-09

**Hazard wards from specialised blueprints.**
- Two new optional modules (size 1), **never sold – only built** at a station's fabricators:
  - **Radiation Insulation** – keeps part of a radiation zone's dose off (shield drain and hull burn), recipe of
    tungsten, armour plating and electronics.
  - **Shielded Hull Lining** – a conductive lining against ion storms: fewer lightning strikes, shorter knock-outs,
    less damage, and the radar is jammed less often; recipe of copper, magnet coils and circuits.
  - The effect depends on the **quality**: F 50 %, E 58 %, D 66 %, C 74 %, B 82 %, A 90 % (the best one fitted counts).
- **Two new tiles in the Industry branch of the skill tree** (after Station Manufacturing) hold the specialised
  blueprints: *Radiation Insulation* (10 modules built, 120 s spent in radiation zones) and *Shielded Hull Lining*
  (10 modules built, 5 ion-storm lightning strikes taken). New achievement metrics for both.

## alpha 0.6.40.8 – 2026-11-09

**Package 40d: the dangers of the Rim.** A new game is needed.
- **Radiation zones** – always round neutron stars and black holes, now and then elsewhere (a quarter of the Rim,
  more in the Far Reaches), often over an asteroid field: inside, shields drain and then the hull burns; the rock
  under a zone is purer and richer. A yellow-green haze with a striped ring; a big warning banner.
- **Ion storms** – blue clouds with lightning that drift slowly through a system: radar jammed, lightning strikes
  knock out shields and systems for a moment and scorch the hull.
- **Old minefields** – round old battlefields or across the way to a gate: 18–30 rusted mines of a forgotten war,
  armed against anyone (pirates and patrols too); point defence shoots them down. A red dashed ring.
- **Pirate fortresses** – six in the Rim, held by the Hollow Crown and the Severed: a hollowed-out rock behind seven
  armoured bastions, heavy guns with a long reach, a garrison of 6–8 ships. Destroy the whole garrison and the
  fortress is **broken**: its guns fall silent and its **bounty (150,000 cr)** is paid as a bond; half an hour later
  it is rebuilt. Fortress systems count as inhabited (German names) and have patched pirate gates.
- Hazards are warp targets (you arrive at their edge), named in the system info of the galaxy map; fortresses are
  marked with a red square. Codex: Radiation zones, Ion storms, Old minefields, Pirate fortresses. Smoke tests.

## alpha 0.6.40.7 – 2026-11-09

**Territories by the lore.** A new game is needed.
- **The Assembly and the Covenant share the core** between them and grow without limit; where they meet, a few
  border systems are **contested** – the only contested systems in the cluster.
  The two stay about the same size (the bigger one cedes border systems to the smaller).
- **The Meridian Directorate is a small enclave:** its capital (one with at most three routes) and the systems round
  it – **at most 4 systems**. No contested border touches it.
- **The pirate factions hold at most 3 systems each.**

## alpha 0.6.40.6 – 2026-11-09

**No more route classes; the Veil as clouds.** A new game is needed.
- **Every hyperspace route is open to every ship with a jump drive** – the route classes (and the drive class they
  asked for) are gone; the systems' own conditions, entry permits and the dangers of the Far Reaches are the
  barriers now. Every jump costs the same fuel.
- The jump drives are **grades Mk I–III** now (the old Cl.1–3 drives): a better drive **jumps faster** (×1 / ×0.85 /
  ×0.7) and holds an old gate's failing field together (**misjumps** ×1 / ×0.6 / ×0.3).
- Galaxy map: all routes in one colour, the route list without classes; gate tooltips without a route class.
- **The Veil on the galaxy map** is a slowly wavering band of **black clouds with violet accents** – violet light in
  their folds and along their ragged inner edge (a shader, `veil_clouds.gdshader`).

## alpha 0.6.40.5 – 2026-11-09

**Package 40c: the content of the Rim.** A new game is needed.
- **Rich deposits:** every Rim system has one more asteroid field (the Far Reaches two), its rock holds 1.5× as much
  ore (Far Reaches 1.8×) and is purer (45 % high grade instead of 20 %), every metallic and stony colossus has a deep
  deposit, and every system a giant to harvest.
- **Old battlefields** (~40 % of the Rim, a few in the core): 6–12 hulks of warships of two old enemies, burnt grey,
  rusted, holed and often broken in two, in a field of scrap. Salvaged: salvage, alloys, weapon parts, sometimes an old
  module and **Pre-Severance Tech**. They stay until salvaged – for good.
- **Pre-Severance derelicts** (more often further out): the colony and generation ships that brought people to the
  Cluster – a long spine, a broken habitat ring, faded paint – with fragments round them. Salvaged: Pre-Severance
  Tech, research data, scrap, and now and then a **Relic of Earth**.
- New good **Pre-Severance Tech** (1,600 cr) – only from the wrecks; research and high-tech worlds buy it.
- **The edge of the Veil:** the two outermost systems of every constellation of the Far Reaches (40 in all), violet on
  the galaxy map. A violet curtain of light in their sky, ghost ships flickering up on the sensors, echoes and voices
  in the log – and **Veil rifts**, jagged tears in space visible from afar: analysing one gives much more data (Veil
  readings for the Research Exchange) and often exotic matter.
- Galaxy map: the Veil glows violet round the cluster, "THE VEIL" in the overview; the system info lists rich
  deposits, battlefields, derelicts and the edge of the Veil.
- Codex: Old battlefields, Pre-Severance derelicts, The edge of the Veil, Veil rifts. Smoke tests for all of it.

## alpha 0.6.40.4 – 2026-11-09

**Galaxy map overview.** Zoomed right out (below ×1.8), the map becomes an overview: system names, security and
station marks are hidden (only your current, the selected and the hovered system keep their names), the territories
are always shown and each faction's name stands over its land (pirate holdings smaller, labels never overlap), and
"THE RIM" and "THE FAR REACHES" are written along their rings.

## alpha 0.6.40.3 – 2026-11-09

**Package 40a extended: the Far Reaches.** A new game is needed.
- Beyond the Rim lies a second ring of **20 constellations** of 5–7 systems each – about **120 more systems**, the
  cluster now has ~240. Nobody lives there: no settlements, no stations, no research posts at the strange stars, the
  lowest security in the cluster (0.0–0.15), old gates everywhere.
- The Far Reaches are reached **only through the Rim** (one or two routes per constellation), their constellations
  joined among themselves by single routes with more gaps than in the Rim – regions you have to go round.
- Territory reads "Unclaimed – the Far Reaches". The galaxy map is larger (5300 × 3600) and zooms further.

## alpha 0.6.40.2 – 2026-11-09

**Package 40b: the gates.**
- Gates now show **whose system it is**, in six drawings: the **Assembly's** white-and-blue ring with four pylons,
  the **Covenant's** crimson and gold with eight spires, the **Directorate's** silver octagon with green emitters, the
  plain yellow-striped gates of the **independents** – and in the empty Rim the **old gates**: rusted, plates missing,
  broken down to the bare frame in places, their field flickering. The **pirates** patch theirs with scrap plates and
  red lights.
- A jump through an **old or patched gate takes longer** (×1.6) and, very rarely (3 %, pirate gates 1.5 %), its field
  breaks down mid-jump: the ship is **flung out somewhere in the target system** (far out or near a field) and takes
  damage (15 % of the hull, armour first – never fatal). The log says what happened and why.
- **Two new animations:** coming out of a gate – the gate flares, the ship shoots out of it and slows to its place
  with a flash and a glittering trail, like dropping out of warp; and the **misjump** – violet lightning, a torn ring,
  the ship thrown out tumbling with sparks and smoke. NPCs make the gate flare too.
- Codex: "Hyperspace gates" tells of the styles, the old gates and misjumps. Smoke tests for the styles and the misjump.

## alpha 0.6.40.1 – 2026-11-09

**Package 40a: the new cluster.** A new game is needed (older saves are moved to the new cluster).
- About **120 systems**: a **core** of ~60 held by the Assembly, the Covenant, the Directorate and – at its edges – the
  pirates, much as before; round it **the Rim**, a ring of **11 constellations** of 4–7 systems each, close together
  and joined among themselves, to their neighbours by a single route (now and then none – regions form) and to the core
  by one or two. The Rim belongs to no one: wild, unwatched, low security.
- **Capitals are ringed by their own systems** – every neighbour of a capital belongs to its power.
- **Free settlements** in most constellations: a small outpost (mining, trade, research or ice), an independent
  system (yellow). The manufacturers' independent homes (Erzhalde, Perlmutt, Schwarzwacht) lie in constellations right
  on the core.
- **Names:** inhabited systems (stations, havens, settlements) German names – 40 new ones; empty systems catalogue
  numbers or the names of their explorers ("KVX-114", "Brandts Wacht", "Ruiz' Hoffnung").
- **Galaxy map: zoom and pan** – it opens zoomed in round the current system; the wheel zooms towards the pointer,
  dragging moves the map. Empty systems show no economy or prosperity; the Rim is "Unclaimed – the Rim".
- The empty systems of the Rim are made when first needed (not behind the loading screen).

## alpha 0.6.43.4 – 2026-11-09

**Package 43c: tourist traffic – Tourismus done.**
- **Cruise liners** of Maison Aurelle (Pearl, Opal and now and then an Empress as a "Grand Liner") come through the
  gates, fly to a sight of the system, drift past it for a while and then berth at the resort; in a well-off system
  with a famous sight but no resort they sail on through a gate afterwards.
- **Sightseeing shuttles** leave the resort for a sight (the rings, a beautiful world, a wondrous star, a landmark),
  linger and fly home.
- Their numbers follow the resorts and the prosperity of the system (Universe.system_profile: cruise, tour_shuttles).
- Debug: cruise liner + sightseers now. Codex "Resorts and sights" mentions them.

## alpha 0.6.43.3 – 2026-11-09

**Package 43b: tourist flights and round trips.**
- **Tourist flights** among the passenger contracts: holidaymakers bound for a resort, more of them in richer
  systems, more often in business and luxury class; they pay 30 % more. Each group delivered raises the resort
  system's prosperity a little.
- **Round trips** (from Average prosperity up): sightseers board here, you take them to a sight in another system
  (up to three jumps) – a beautiful world, the rings of a giant, a wondrous star, a landmark – stay close, out of warp,
  for 45 seconds while they look, and bring them back to where they boarded. The deadline covers the whole trip; the
  more famous the sight, the better the pay. The sight's system gains a little prosperity.
- The board marks them "TOURISTS" and "ROUND TRIP"; the contract shows how long they have looked.
- Codex "Tourists and round trips"; debug: round trips – sight seen.

## alpha 0.6.43.2 – 2026-11-09

- Resorts redrawn: the big ones (tier 3) are **habitat rings** – a wide ring with a landscape under a glass roof:
  meadows, forests, lakes and towns, walled on both edges, half of it in night with the towns' windows lit and lights
  twinkling over them; spokes to the hub, docks at the rim. The smaller ones are **biospheres** – a great glass dome
  over the same landscape, half in night, with a service ring and docks. Names: "… – Habitat Ring" / "… – Biosphere".
  (The ring resort, observatory and pleasure dome looks are gone.)

## alpha 0.6.43.1 – 2026-11-09

**Package 43a: resorts and sights.** A new game is needed.
- New station type **Resort** (ivory and gold) in three looks: a **ring resort** of hotel decks with a garden dome and
  glass observation pods at a ringed giant, an **observatory resort** with a great telescope, a glazed gallery and a
  viewing bubble at a wondrous star (red supergiant, neutron star, black hole, blue giant), and a **pleasure dome** –
  an octagonal casino under glass, neon on every edge and a great wheel – at a beautiful world.
- Resorts stand where a holiday is worth it: earthlike, ocean and jungle worlds, ringed giants, wondrous stars, safe
  and wealthy systems – about ten in a cluster; Landfall, Heimkehr and Perlmutt always have one.
- Tourism trade: resorts sell souvenirs, holo films and art and want luxuries, fine food, wine, perfume and gold; a
  resort gives its system a strong tourism economy.
- The sights of a system (beautiful worlds, the rings of the giants, wondrous stars, landmarks such as The Vote, the
  Pilgrim Gate and the Meridian Sphere) – for the round trips of package 43b.
- The station column of the concourse shows the system's economy and what this market makes and wants (it still
  showed the old station-type lists).
- Codex "Resorts and sights"; debug: to a resort.

## alpha 0.6.42.5 – 2026-11-09

**Package 42d: tuning – Wirtschaft 2.0 done.**
- Trade balance checked across two clusters: no market ever buys back above its price; the best routes earn about
  10,000–14,000 credits per 100 m³ load over one jump (artworks, fuel rods, medical isotopes, magnet coils – limited by
  the stock), a hold of ore about 5,000, contracts 5,000–20,000.
- Waystations keep to their own goods (water, food, fuel) and the basic needs instead of taking on the system's whole
  economy.
- Prosperity rises a little faster with trade: a level is about 100,000 credits of wanted goods (was 120,000).
- Galaxy map: how far a system's prosperity has moved from its usual level ("+8 from its usual 52").
- Codex entry "Munitions Depot".
- Fixed: a few texts had a line break written into the code instead of an escape (no visible change).

## alpha 0.6.42.4 – 2026-11-09

**Package 42c: prosperity changes and shapes the systems.**
- Prosperity moves: selling a system what it wants and buying what it makes raise it, so do finished contracts and
  pirates shot down there; a raid that knocks out a station costs 10 points. Left alone it drifts back to its base
  (most of the way in about two hours). The news report when a system rises or falls a level.
- Rich systems are busier (more shuttles and haulers) and get an extra patrol; poor ones draw more pirates.
- Contracts: rich systems offer one more and pay up to 15 % more, impoverished ones one fewer and up to 15 % less.
- Outfitters: high-tech, wealthy and rich systems carry one quality step better than the station's tier allows;
  military systems carry A quality and every size of weapon and armour up to the tier; impoverished systems lose A.
- Convoys carry what the source market makes, bound for a market that wants it; richer systems send more of them.
- The loading screen prepares every system's layout and markets (the galaxy map and the convoys need them) – no hitch
  later.
- Debug: prosperity drift 1 h. Codex "Economies and prosperity" updated.

## alpha 0.6.42.3 – 2026-11-09

- Market: the goods are grouped in **sixteen categories** – ores, ices, gases, metals, minerals, nuclear materials,
  fuels & coolants, components, food, chemicals, industrial goods, consumer goods, high-tech & medical, science,
  military goods, luxury goods – with a heading per group and a filter for each (the economy filters stay below).
- Raw materials are wanted by their own users now, not all by "industry and high-tech": tungsten and titanium by the
  military, helium-3 and cryo coolant by research, ammonia and carbon dioxide by agriculture, xenon by the military …
- Weapon parts are made by industry and used by the military.
- New service **Munitions Depot** (Obsidian Ordnance): ammunition for every weapon that has to be restocked – the
  mines of the mine launchers so far; mines are no longer sold on the market. What a depot stocks and charges follows
  the economy: military systems carry every kind and sell it cheapest, industrial ones the common kinds, high-tech
  ones the jammer mines; pirate havens sell everything, dearly. Munitions go back for half their price.
- `Warenliste.md`: all tradeable goods with category, producing and consuming economy.

## alpha 0.6.42.2 – 2026-11-09

**Package 42b: markets with real stocks.** A new game is needed.
- 56 new goods of the nine economies – grain, coffee and fine wine; drill bits, gemstones and industrial diamonds;
  machinery, robots and prefab habitats; steel, refined fuel and glass; plastics, explosives and fertiliser; computers,
  nanites, implants and AI cores; star charts and prototypes; ammunition and body armour; souvenirs, jewellery,
  perfume and artworks. Some are trade goods only. The older goods have their place in the economies too.
- Every good has a role at each station: **made here** (green – its station, or the system's main or secondary
  economy; ores only where the system's fields hold them, gases only where a giant gives them), **wanted here**
  (gold – its station, the economies that need it, luxuries in wealthy and rich systems, basic needs everywhere) or
  neutral.
- **Real stocks:** buying takes from the stock and raises the price, selling fills it and lowers the price (whole
  sales are priced along the way). Over game time the stocks drift back: made goods are made again, wanted goods
  used up, neutral goods carried off. Richer systems keep bigger stocks and pay a little more. Traded stocks are saved.
- Market screen: the economy and prosperity of the system, what is made and wanted here, a stock column, filters for
  local trade, the hold, raw materials, components, luxury goods, all and each of the nine economies. The galaxy map
  lists what each station's market sells and buys.
- Codex entry "Markets and stocks"; debug: markets +1 h, +20 luxury goods.

## alpha 0.6.42.1 – 2026-11-09

**Package 42a: Wirtschaft 2.0 – the economic model.** A new game is needed.
- Every system has a **main economy** and, if strong enough, a **secondary** one: Agriculture, Mining, Industry,
  Refining, Chemistry, High-Tech, Research, Military or Tourism. They come from the system's factors – its stations
  above all (they are fixed and shape the economy), then its planets, moons, asteroid fields and belts. Ocean and
  jungle worlds feed, metal worlds and fields are mined, gas giants power industry, red and toxic giants supply the
  chemists, earthlike worlds draw tourists and high-tech firms. The hand-made systems lean towards their own.
- **Prosperity** in five levels (Impoverished, Poor, Average, Wealthy, Rich): it starts from a system's people,
  stations and security, is saved with the game and will change in play (package 42c).
- New planet type **Metal World**: a dense iron world laced with copper and silver ore veins that glint in the sun –
  the strongest mining factor. In the collection too.
- Galaxy map: the economy filter now highlights the nine economies (main or secondary); a coloured mark above each
  system shows its main economy, five pips its prosperity; the system info names the economy, its strongest reasons
  and the prosperity. The header shows the economy of the current system.
- Codex entry "Economies and prosperity"; debug section "Economy (package 42)": the factors in the log, prosperity
  ±20, to a metal world, to a system of each economy.

## alpha 0.6.41.6 – 2026-11-09

**Performance on the system map.** Fully zoomed out: 8–12 ms per frame (spikes to 28 ms) → about 4 ms (spikes to 8 ms).
- Dashed rings (no-fire zones, harvest bands) are one draw call each instead of one per dash (90 per station), and
  are left out where they would be a speck.
- NPC ships smaller than a pixel on screen are hidden and not redrawn (the map marks them); effects and stations that
  would be a few pixels are not redrawn either.
- The belt dashes on the map are only rebuilt when the zoom changes.

## alpha 0.6.41.5 – 2026-11-09

**Performance.** The game logic runs on one CPU core (GDScript), so a busy system could drop to 20–50 FPS while the
PC looked idle. Measured in the start system: 19 ms per frame (spikes to 38 ms) → 2.5 ms (spikes to 5 ms).
- Effects (warp glitter trails, explosions, beams, smoke) are only redrawn while on screen; a glitter trail has about
  half the sparks.
- Stations, structures, gates and NPC ships are only redrawn while on screen.
- What is under the mouse is looked up when the mouse moves, otherwise ten times a second (it walked all ~1,700
  objects every frame); hidden rocks are skipped at once.
- NPC ships check their power plan four times a second instead of every frame.

## alpha 0.6.41.4 – 2026-11-08

- Inventory: the gas tanks and shielded racks get their own bars under the cargo hold (used / room); gas in the
  ordinary racks is shown with the room it takes there (twice its volume); radioactive goods outside shielded racks
  get a warning line. Gases are marked "(gas)", radioactive goods ☢.
- The ship info (HUD and the Info tab) shows the gas tanks and shielded racks next to the cargo.

## alpha 0.6.41.3 – 2026-11-08

- Fixed: the ship menu's Modules tab crashed with a gas collector or deep core drill fitted (the tool kinds had no name).

## alpha 0.6.41.2 – 2026-11-08

- Fixed: switching on the gas collector (the Kujira's scoop above all) crashed the game – it has no target.
- No more funnel: ships with a drone hatch open it and the gas streams in through it; ships without one take the gas
  in on their underside (the stream vanishes under the hull). The gas comes in from ahead, where the ship is flying.
- Kujira: the funnel at the bow is gone – a slightly raised bridge with cockpit glass sits on the nose now, and a
  drone hatch on the spine between the last tank and the bridge (two drones, crew posts).

## alpha 0.6.41.1 – 2026-11-08

**Package 41: the mining expansion.** A new game is needed.
- 12 new ores with their refined materials: copper, tungsten, gold, uraninite, spodumene (lithium), graphite, quartz,
  monazite (thorium), nitrogen ice, dry ice – and osmium and palladium, found only as deep deposits in colossi.
- Purity: every asteroid is low, medium or high grade (the prospector reads it); purer rock gives more ore.
- **Gas harvesting:** every giant has a harvest band (dashed rings on the map). Fly through it with a gas collector on
  and keep moving – the scoop swings out and draws a stream of gas in. Deeper means more gas; below the inner ring heat
  and pressure wear armour and hull past the shields. Storms double both. Gas giants give hydrogen and helium (rarely
  helium-3), ice giants nitrogen and neon (xenon), red giants hydrogen and sulfur dioxide (phosphine), toxic giants
  chlorine and ammonia (fluorine).
- New modules: Gas Collector (1–4), Deep Core Drill (2–4, colossi only), Gas Tanks, Shielded Cargo Rack.
- Gases take twice the room in ordinary racks; gas tanks hold them at their own volume.
- **Radioactive goods** (uraninite, monazite, enriched uranium, thorium, fuel rods, tritium, medical isotopes) outside
  shielded racks raise a red RADIATION banner with an alarm. Shielded racks hold far less per size.
- **Components** at any station with fabricators: circuit boards, battery cells, armour plating, carbon fiber, ion
  propellant, magnet coils, fusion cells, fuel rods, tritium, medical isotopes, precision optics, cryo systems.
- **KHI Kujira** (L gas freighter): big round tanks, 1,600 m³ of gas, a built-in scoop, heat resistant hull.
- Codex entries, debug section "Mining expansion (package 41)", smoke tests.

## alpha 0.6.39.11 – 2026-11-08

- Yards: the docking bays of the Atelier Aurelle and the Hadrian Foundry are flush with the hull now (arms and
  docking blocks as wide as the bays); the berths' girders no longer jump a pixel half-way (Kanayama Works).

## alpha 0.6.39.10 – 2026-11-08

**Package 39d: the manufacturers' systems.** A new game is needed.
- Earthworks: **Altwerft** in the Assembly's space – the Earthworks Second Yard (12696 HE), the standard yard design.
- New class of systems: **independent** (yellow on the galaxy map), no power holds them:
  - **Erzhalde** – Kanayama Works: a yellow building site with scaffolding, tower cranes and a smoking refinery block.
  - **Perlmutt** – Atelier Aurelle: slender and rounded, ivory and gold, a glass dome with a biosphere at its heart.
  - **Schwarzwacht** – Hadrian Foundry: black and angular with red lights; weapon platforms are being built round it,
    drones at work.
- Every maker's yard sells all of its ships, and the berths hold them under construction (scaffolding, sparks, drones).
- Codex entry on independent systems; debug: jump to each maker's system.

## alpha 0.6.39.9 – 2026-11-08

- Axiom Yards reworked: the spine ends at its sensor hub instead of running off the left edge; in the berths lie the
  manufacturer's own ships – two Thresholds and two Parallaxes – under scaffolding, a section still open.
- Work drones hop round the unfinished jump gates, welding.

## alpha 0.6.39.8 – 2026-11-08

- Durchbruch: big haulers carry Dyson plates along the shell near the Meridian Sphere (out loaded, back empty).
- The solar mirrors over Curie are curved reflectors now, turned to the planet as you see it in the sky – their
  facets gather the light into a beam that lands on the surface.
- Curie has a research station: the Curie Terraforming Institute. A new game is needed.

## alpha 0.6.39.7 – 2026-11-08

- Fix: the debug menu crashed the game ("Invalid access … 'desert'") – Vesper, Heimkehr's desert moon, is a moon of a
  planet type, and a few places looked moons up among the moon types only (debug menu, moon fields, debug jump to a
  moon). The smoke test now opens every debug tab in all three capitals.

## alpha 0.6.39.6 – 2026-11-08

**Package 39c: Durchbruch, the capital of the Directorate.** A new game is needed.
- A blue-white A star – and round it a **Dyson sphere under construction**: frame rings of the shell, closed with
  silver collector plates where they are built, bare scaffolding (welders at work) where not. Its hub, the **Meridian
  Sphere**, is the only station in the Cluster built round a star.
- Physicists: Noether, **Curie** (half terraformed – green with seas on one side, desert on the other, three solar
  mirrors beaming light onto the new land), Planck with Meitner and Bohr, Kepler.
- **Axiom Yards** at Meitner: sleek berths, ships testing their cloaks, and six **small jump gates** being built round
  the yard (now and then one is test-fired). The Threshold is sold only there.
- **Research Exchange** (Meridian Sphere): research data from analysed anomalies and exotic matter for credits and
  standing; exotic matter for sale to Allied pilots.
- Contracts: measurement probes, exotic matter for the Sphere, test flights from the Axiom Yards; codex entries; debug.

## alpha 0.6.39.5 – 2026-11-08

- Pilgrim Gate: rays from the tips of its spires gather in a burning focus ahead of the gate; from there the mighty
  beam runs home right across the system map.
- Cathedral of Return in crimson and gold instead of pale stone.
- New planet type **Red Gas Giant** (Compline is one) – it now turns up elsewhere too and has its tile in the
  collection. A new game is needed.
- Work drones hop over the Lux Aeterna from one welding spot to the next.

## alpha 0.6.39.4 – 2026-11-08

**Package 39b: Heimkehr, the capital of the Covenant.** A new game is needed.
- Heimkehr under a red supergiant: the lava world Lauds, the red gas giant Compline (no rings) with the desert moon
  Vesper (pilgrim cities) and Nones, the ice world Matins.
- The Cathedral of Return over Vesper – pale stone, stained glass, a rose window ringed in gold, spires; modern docking
  arms and solar sails beneath the old forms.
- The Pilgrim Gate: a ceremonial ring of ivory and gold that points home; its light never goes out and pilgrims pass
  through it in an endless line.
- The Forge of Return at Lauds: furnace towers, a farm of red focus crystals, a warship in its berth – the only yard
  that sells the Cathedral. Beside it the Lux Aeterna: the Covenant's capital ship, crimson and gold, a great focus
  crystal at the bow, huge weapon towers, a habitat ring at her heart.
- The Curia (Cathedral of Return): the Hierarch's edicts (each with a blessing and a burden), tithes (standing, a
  petition for the next edict), indulgences (wipe your record with the Covenant), relics of Earth (found in anomalies –
  standing and a blessing: cheaper prices at Covenant stations).
- Contracts: pilgrim convoys and crystal transports to Heimkehr, relic recoveries; codex entries; debug functions.

## alpha 0.6.39.3 – 2026-11-08

- The background stars twinkle much less – a gentle, slow shimmer instead of blinking.

## alpha 0.6.39.2 – 2026-11-08

- Agora's city lights have structure: bright metropolises, a glittering band along the coasts and highways between
  them – the open land and the sea stay dark.
- Much busier drone traffic between The Vote and its relay stations (two lanes each way).
- The Res Publica redesigned after Luz's reference: a long bow split by the trench of her spinal railgun, broad
  shoulders, swept wings at the stern with the engine core between them, drone hatches all over the hull (drones
  launch and land), a wing still under scaffolding; her stern lies against the yard's gantries.

## alpha 0.6.39.1 – 2026-11-08

**Package 39a: Landfall, the capital of the Assembly** – the first hand-made special system. A new game is needed.
- The Assembly's capital is now Landfall: G star, Pnyx, Agora (brightest city lights), Ekklesia and the deep-blue ice
  giant Boulé with Ostrakon and Kleros.
- Capitals are closed: an entry permit from Friendly standing on (taken only at Arch-enemy) opens the gates.
- The Vote: trade hub with four relay stations, drone traffic and a blue beam that sends ballot drones to the gates.
- The Senate: bills every 30–60 min with an upside and a price for an hour; votes, party donations, bribes.
- Concord Yards with the Res Publica in her berth; the Concordia is sold only there.
- Ballot couriers and drone field trials; codex entries Landfall and The Senate; debug functions.

## alpha 0.6.38.2 – 2026-11-08

- Collection: moon types are a category of their own (Moon types), apart from the planet types.
- Collection tiles grow with the screen – picture, text and tile size scale up on large screens, and the tiles
  stretch so each row fills the width.

## alpha 0.6.38.1 – 2026-11-08

**Package 38: new planet types.** A new game is needed.
- New: ice giants, dwarf planets out in the Kuiper belt, ocean worlds and jungle worlds. Now and then a waystation
  orbits a dwarf planet.
- Every planet type reworked, twice as fine: seas and coasts, a cloud layer of its own, polar caps, a twilight edge,
  glowing lava flows, banded giants with vortices and great storms, craters, rings in many shapes – and every planet
  its own shade of its type.
- City lights on the night side of habitable worlds in inhabited systems.
- Collection → Planet types: a tile per planet and moon type with picture, size, mass, temperature and description.
- Debug: jump to a planet of each type.

## alpha 0.6.37.6 – 2026-11-08

- The plasma arc of a coronal mass ejection no longer stops at a straight edge – it fades out before the star's
  picture ends.
- **Eruptions by star class:** red dwarfs and red supergiants erupt far more often (a red dwarf every 3–7 minutes),
  hot blue stars rarely (every 14–30).
- Flares on the star's disc smaller, rarer and in the star's hot colour instead of white.

## alpha 0.6.37.5 – 2026-11-08

- **Coronal mass ejection:** inside the shockwave (combat and recon view) plasma streaks race across the screen away
  from the star and the light turns warm.
- Debug: the coronal mass ejection starts at the countdown (banner and alarm, 10 s to the eruption).

## alpha 0.6.37.4 – 2026-11-08

**Coronal mass ejection warning:** 10 s before the eruption a red, bold, pulsing banner top centre – "! ENERGY SPIKE
DETECTED ON THE STAR !" with a countdown – and a calm, alien alarm that fades in and out (sound: "extraterrestrial
alert sound" by fnx_sound, Pixabay). The audio system now plays MP3 as well.

## alpha 0.6.37.3 – 2026-11-08

**Zooming between the recon view and the map:** the planets, moons and the star glide from their place in the sky to
their place on the map (and back), the zoom passes the change at an even pace (about 0.6 s), and a holo grid flashes
up while a scan line sweeps the screen – like a cockpit display switching to the tactical view.

## alpha 0.6.37.2 – 2026-11-08

- **Neutron stars** blaze much brighter – a bright point even on the system map.
- **Warp** from 12,000 km (was 40,000): planet to moon no longer means minutes of sublight flight.
- **Star classes in the Collection** (instead of the codex): a tile per class with a small animated picture, size in
  solar radii, mass in solar masses, surface temperature and a description; classes not yet visited show as "???".
- **Coronal mass ejections** hit harder: a ship in warp is torn out of it (emergency shutdown), cloaks fail for 20 s,
  drones are knocked out for a few seconds (white lightning), mines go off.

## alpha 0.6.37.1 – 2026-11-08

**Package 37: new star types.** A new game is needed.
- Twelve star types: the main sequence O, B, A, F, G, K, M, pink brown dwarfs, red supergiants (ten times a G star –
  the planets move out), white dwarfs, neutron stars and black holes (only in systems without stations, now and then
  with a research station).
- All animated in a finer pixel style: boiling surfaces, sunspots, prominences rising and falling on the limb, flares;
  a neutron star with huge glowing field lines and sweeping jets; a black hole with its turning accretion disc, the far
  side bent over the hole, and a gravitational lens bending the stars behind it.
- Coronal mass ejections: warning in the log, an eruption on the star, then a shockwave races through the system –
  sensors jammed, shields weakened (collapsed close to the star).
- The solar collector draws by the star's brightness; a black hole pulls ships in close up and crushes what crosses
  its horizon.
- Codex entries; debug: any star type in the current system, an ejection at once.

## alpha 0.6.36.7 – 2026-11-08

**Depth:** the parallax of planets, moons and stars now depends on how close they are – a near planet glides by as a
layer of its own (slower than the ships, clearly faster than the stars), a far one hardly moves; right above a body it
slides smoothly under the ship.

## alpha 0.6.36.6 – 2026-11-08

**More impressive planets, moons and stars:** about as big as before from afar, but growing ever more steeply towards
the surface – right above a planet it fills the screen (about 1,050 instead of 650 px radius at 1080p). The star is
half again as big and has a wide, soft corona.

## alpha 0.6.36.5 – 2026-11-08

**Station orbits:** like moons, stations have their own orbit round their planet or moon and stand somewhere else on it
each time you jump in (the rocks round a station go with it); the orbits show in the Orbit view. Waystations stay on
their gate route. A new game is recommended.

## alpha 0.6.36.4 – 2026-11-08

**Emergency shutdown** on the warp key (X): in warp it only does the shutdown – once asks, again within 5 s drops out.
Space did not get through (it also presses focused buttons) and centres the camera again.

## alpha 0.6.36.3 – 2026-11-08

- **Warp** half again as fast.
- **Emergency shutdown:** Space in warp asks in the log; Space again within 5 s throws the ship out of warp – flash,
  glittering trail, and it tumbles three times round itself before it answers the helm (the drive needs 6 s).
- **Planets, moons and stars** come much closer (right above a planet about 650 instead of 450 px radius at 1080p) and
  grow and shrink smoothly – no hard limits, a fixed pixel grid instead of one that jumped with every change of size.

## alpha 0.6.36.2 – 2026-11-08

**Orbit view:** a new zoom level between Recon and System (F3; System is now F4) – a flat map 260,000 km round the ship,
enough for a planet with all its moons, their orbits and names. Not during a warp (the wheel skips it). Saved zoom keys
are reset once to the new defaults.

## alpha 0.6.36.1 – 2026-11-08

**Package 36: moons.** A new game is needed.
- Gas giants have 2–3 moons, rocky worlds mostly one; four kinds: rocky (craters), ice, volcanic (glowing volcanoes) and
  captured asteroids (lumpy). 3,000–7,800 km across the radius – far bigger than colossi. Named after their planet
  ("Sonnenwende V-a").
- Every time you jump into a system, the planets and moons stand somewhere else on their orbits; stations, ring rocks
  and moon fields move with them. Saved with the game.
- Some stations orbit a moon; every fourth moon has a small asteroid field; pirates hide behind moons.
- Moons are warp targets and show in the overview and on the system map (orbits and names when zoomed in).
- Debug: moons of the system, jump to a moon (of each kind), roll the orbits.

## alpha 0.6.35.17 – 2026-11-08

**Warp to stations:** stations and pirate havens can be warped to from 8,000 km (other targets still 40,000 km). Standing just outside a no-fire zone used to mean minutes of sublight flight; now a ship always arrives 2,500 km from the station.

## alpha 0.6.35.16 – 2026-11-08

**Fixed:** the recon view slowed to about 10 FPS in asteroid fields with colossi. Slices of the radar shadows could be twisted, and every failed triangulation logged an error, several times a frame (about 95 ms a frame, now about 20 ms). Contacts out of radar range are skipped before the sight-line check.

## alpha 0.6.35.15 – 2026-11-08

- **Warp:** the lines streaming behind a ship in warp are gone (the friction glow replaces them).
- **FPS display** in the top bar, left of the Ship / Pilot / Map buttons: frames per second and the slowest frame, green / yellow / red; can be switched off in the settings.

## alpha 0.6.35.14 – 2026-11-08

**Warp:** the tunnel and the warp trail reach only from the start to the end of the warp (on the system map they ran to infinity). Fixed: the system map stuttered badly during a warp – thousands of tunnel rings were drawn every frame (about 170 ms a frame, now about 17 ms).

## alpha 0.6.35.13 – 2026-11-08

**Warp:** no more slowing down at the end – after accelerating, the ship flies at full speed right to the destination and drops straight to sublight; the exit flash appears at the point of arrival.

## alpha 0.6.35.12 – 2026-11-08

**Warp:** a much brighter flash going in; the flash coming out comes a moment before arrival; the glittering trail is shorter (about 3.5 s). Instead of the arc in front of the ship, every ship in warp glows like a ship entering an atmosphere, only bluer – a hot sheath round the bow, flickering tongues of flame and sparks streaming back.

## alpha 0.6.35.11 – 2026-11-08

**Warp trail:** instead of smoke, a long glittering trail along the course (7,500 km, longer than the combat view), brighter towards the ship; it flares up all at once, then fades from the far end towards the ship.

## alpha 0.6.35.10 – 2026-11-08

**Warp:** a bright flash of light going into and coming out of warp; every ship leaves a small bluish trail of smoke when it drops out, fading after a few seconds.

## alpha 0.6.35.9 – 2026-11-08

**Warp tunnel:** a fixed size (1,300 km radius) – big at close range with room for the whole formation, a narrow tunnel on the recon view; always centred on the ship leading the formation.

## alpha 0.6.35.8 – 2026-11-08

**Warp:** the radar is hidden during a warp (it showed in recon by mistake in 0.6.35.7).

## alpha 0.6.35.7 – 2026-11-08

**Warp:** the camera stays at close range (zoom out by hand whenever you like – the radar now shows in recon during
a warp too); a new warp animation: a pale blue tunnel forms round the ship, rings and streaks rush past.

## alpha 0.6.35.6 – 2026-11-08

**Ice colossus:** the spiked crystal is now a rounded ice ball with soft bulges.

## alpha 0.6.35.5 – 2026-11-08

- Radar shadows end at the radar range.
- Two new colossus shapes for each kind of rock: metal slab and spindle, stone rubble pile and kidney, ice teardrop
  and spiked crystal – with matching radar shadows.
- Colossi can be mined: a huge deposit of two ores; mined out they stay and show as empty.
- Small asteroids mined out break apart, the pieces drift and fade; they grow back after 30–60 minutes.

## alpha 0.6.35.4 – 2026-11-08

**Asteroid fields:** more compact (12,000–22,000 km) and made of many small structures – dense knots, patches and streams – with open space between them and some very dense spots. Every field now has 3–5 colossi (one more in lawless space).

## alpha 0.6.35.3 – 2026-11-08

**System map centred on your ship again** (as before); the camera-limit fix from 0.6.35.2 stays.

## alpha 0.6.35.2 – 2026-11-08

**System map centred again:** the map is centred on the star (Godot's default camera limits had pushed the map of the bigger systems aside); the camera glides between map and close view.

## alpha 0.6.35.1 – 2026-11-08

**Part 6 begins – package 35: system scale.** A new game is needed.
- Systems are three times as big (6 million km); warps are faster, crossing a system takes 20–30 s.
- Asteroid belts and Kuiper belts as scenery: a band on the system map, rocks drifting in the background close up.
- Asteroid fields lie in the belts, are bigger and denser and come in five styles (clustered, band, dense core,
  boulder field, gravel field).
- More traffic (about half again as much, up to 90 ships per system).
- A short loading screen at the start; asteroid pictures and the colossus shader are made ahead of time (no more
  hitch when entering a field with colossi), the next system during the hyperspace jump.

## alpha 0.5.34.4 – 2026-11-08

**Part 5 review fixes** (reviews/teil5_review.md): wingmen and the platform ship keep to no-fire zones (self-defence
allowed) and are repaired when docked, their damage survives jumps; the SHIP LOST window takes every key; leaner saves
(only current bar offers and crew quarters with someone in them); the wingmen panel hides in hyperspace; debug
"Lose the active ship" works in god mode; dead code removed.

## alpha 0.5.34.3 – 2026-11-08

**Collection:** the categories as a list of buttons on the left, the chosen one on the right.

## alpha 0.5.34.2 – 2026-11-08

**Wanted posters:** the ship's icon (in the captain's paint) beside the ship's name.

## alpha 0.5.34.1 – 2026-11-08

**Package 34 – codex, collection, wanted posters** (the last package of part 5).
- Notorious pirates are characters: a face and Piloting & Gunnery that grow with their stars and work on their ship.
- The Bond Office shows Wild West wanted posters: WANTED, the mugshot, the stars, DEAD OR ALIVE, the reward, the ship
  and the escort.
- Pilot window → Pilot → Collection: crew perks you have had (the rest "???") and the posters of the notorious
  pirates you destroyed.
- Codex: new category Pilot & Crew (8 entries), unlocked at first contact.

## alpha 0.5.33.1 – 2026-11-07

**Package 33 – wingmen** (mercenaries for ground combat follow in part 7).
- Pilots for hire at The Bar: real characters with Piloting and Gunnery, two traits and their own ship with a
  standard fit; contracts of 30, 60 or 120 minutes, paid up front, plus a share of the income (F 2 % … A 20 %).
- They fly in formation, warp and jump with you (and follow whom you follow), dock with you; orders aggressive,
  defensive, passive and "attack my target" in the WINGMEN panel (keys N and Y; the others can be bound).
- At most two (the second with Leadership 3); Leadership makes them better and cheaper. Skill tree: Wing Command.
- Citadel: a Hadrian S ship on the launch platform, flown by a Co-Pilot with the new perk Wingman; launch and recall
  in space; destroyed, it can be recalled at a hangar for 10 %.

## alpha 0.5.31.5 – 2026-11-07

**The rebuild summary as tiles:** the lost ship, the respawn station, the crew (in the pod with its signal time / lost), cargo and losses; on the right the costs (hull, modules and drones), the total, the remaining balance, REBUILD and the starter ship – which asks once more.

## alpha 0.5.31.4 – 2026-11-07

**Package 31a – losing the ship.**
- Every crew member rolls to survive (better quality, better odds; Lucky, Medic); survivors drift in an escape pod
  at the wreck – visible in space, on the radar and in the overview – until the signal fades (5–22 minutes by
  quality). Fly within 2,500 km to take them aboard.
- The pilot comes back at the last station docked at in a Dragonfly; the SHIP LOST window offers to rebuild the
  lost ship for 10 % of its value (hull, modules, drones).
- New crew perks: Cargo Insurance (the hold comes back with a rebuilt ship), Insurance Agent (rebuild 5 % cheaper).

## alpha 0.5.31.3 – 2026-11-07

**Station concourse:** the station service tiles grow with the window (the icon too); when space runs short only the services scroll, not the whole column.

## alpha 0.5.31.2 – 2026-11-07

**Station concourse:** the station services are squarer tiles, two in a row (The Bar and the Image Studio among them).

## alpha 0.5.31.1 – 2026-11-07

**Package 31 – the crew and The Bar** (packages 31 and 32 together).
- Ships from M up have crew posts (2–10), some required: without them the ship cannot undock; a bought ship comes
  with rookies (quality F) on the required posts.
- Random crew: name, portrait, profession (7), quality F–A, one rolled bonus, very rarely a perk (e.g. Second
  Profession). They learn from the right work and step up with a rolled improvement. The crew of the active ship
  takes a small share of sales, bounties and contract rewards.
- Ship menu → Modules → CREW; The Bar on the concourse to hire; crew quarters at every station; skill tree: hull
  tiles bring their professions, new tile Science Officers; debug functions.

## alpha 0.5.30.5 – 2026-11-07

**Pilot window:** the Pilot tab comes first and U always opens it. It has three sub-tabs: Info (portrait, name,
level, attributes and all statistics – finances, flight & combat, work, contracts), Standings and Codex (both moved
from the ship menu). The ship menu keeps Info (news, active ship, contracts, fleet), Modules, Ship, Inventory,
Transactions, Industry and Market. The HUD hint opens the skill tree or the perks.
Smoke test: `-- --smoketest --only=pilot,codex` runs single test groups.

## alpha 0.5.30.4 – 2026-11-07

**HUD:** the Ship, Pilot and Map buttons moved to the top right, where the old buttons were.

## alpha 0.5.30.3 – 2026-11-07

**HUD top bar:** three icon buttons top right – Ship [I], Pilot [U], Map [M]; the Pilot button glows green when
skill tree tiles or perk points wait. The zoom, station and help buttons are gone (F1–F3, L and H still work).

## alpha 0.5.30.2 – 2026-11-07

**The skill tree as a real tree** – a new game is needed.
- Drawn as a tree: the Pilot Licence is the trunk, Shields above it, then branches by activity (defence, combat,
  mining, industry, flight, exploration, security, trade, drones); mastery are the roots. Drag it, walk it with
  W/A/S/D, the detail of a tile on the right.
- Everything can be bought; using needs the tile: a locked ship stays docked, a locked module stays offline, a
  locked core module cannot be fitted (fitted ones keep working). Station manufacturing has its own tile.
- New achievement: damage taken (defence branch).

## alpha 0.5.30.1 – 2026-11-07

**Package 30 – perks and the skill tree.**
- 40 skill tree tiles in eight branches open by achievements and are confirmed; they gate buying ships and modules
  and manufacturing (blueprints) – owned ships and modules stay usable.
- 24 perks in six groups, one point per pilot level; their effects work (crew perks with packages 31 and 33).
- Pilot window: Skills, Perks, Skill tree, Pilot; HUD hint for tiles to open and perk points; debug: unlock all.

## alpha 0.5.29.2 – 2026-11-07

- Skills rise by themselves (no more confirming); a new pilot level fed by all experience, every level a perk point.
- Skill bonuses only on the ships the pilot owns. Roadmap: the new progress design and a proposal for perks and the
  skill tree tiles (package 30).

## alpha 0.5.29.1 – 2026-11-07

**Package 29 – skills and the Pilot window.**
- Twelve skills from the attributes, levels 0–10 (+1 % each), experience by doing; an advance is confirmed.
- Their bonuses work on the pilot's own ships (speed, damage, power, scanners, warp, mining, prices, rewards …).
- Pilot window [U]: skills, skill tree preview (package 30), the pilot; the HUD shows a ready advance.
- Debug menu → Character: skill levels, experience, the bonuses at work.

## alpha 0.5.28.3 – 2026-11-07

**Package 28 – the pilot and character creation.**
- The pilot is part of the save: name, call sign, looks, five attributes.
- Pixel construction kit: one look makes the 48 × 48 portrait and the 16 × 16 top-down figure (15 options, 94 choices).
- Character creation at the start of a new game; the Image Studio (Visage Clinics) changes the looks at stations.
- The concourse shows the portrait and the attributes; debug menu → Character.

## alpha 0.5.28.2 – 2026-11-07

- Menus by keyboard: W/A/S/D (and the arrow keys) move the highlight, Enter/Space press, Q/E switch tabs, Escape
  goes back; while a menu is open the ship does not fly. A key group "Menus" of its own in the key bindings.

## alpha 0.5.28.1 – 2026-11-07

**Package 28a – the audio framework (part 5 begins).**
- Audio autoload with channels (music, atmosphere, effects, interface), volume sliders per channel in the settings.
- 36 synthesised placeholder sounds (priority A of docs/audio/sound_list.md) wired to game events: engine, warp,
  jumps, docking, weapons, hits, explosions, modules, drones, interface, purchases, contracts, messages, alarms, space.
- Debug menu → Audio: play every sound, live channel levels, event log.

## alpha 0.4.25.47 – 2026-11-07

**The rest of the part 4 code review.**
- Leaving NPC carriers take their drones along quietly; a hit ends the cloak, which also costs energy in warp
  and for NPCs; the focus lance breaks off when its target warps or cloaks; the trader drone holds the runway.
- Smaller fixes: wormhole location text, factory jobs of lost ships, drones in the ship value, empty storage
  entries, real reasons in the outfitter, debug teleport never to a waystation with an L ship, "wait" state.
- Performance: power plan only on changes, drone lists once per frame, cached hull data.
- Keyboard flight through the command bus; clean-ups; 8 new checks.

## alpha 0.4.25.46 – 2026-11-07

**Fixes from the part 4 code review (the top 5, report in reviews/teil4_review.md).**
- Drones removed before take-off give their place in the deck / hatch queue back (trader drones no longer wait for ever).
- A new order during an approach or landing breaks it off cleanly (pad freed, hatch shut, ship full size).
- The bundled focus lance draws the power of all its crystals.
- Point defence, auto mode, anti-drone pulse and mine settings are kept with the ship (jumps, saves, docking).
- Ships waiting inside a waystation cannot be targeted; wormhole jumps stow the drones first and refuse in warp.

## alpha 0.4.25.45 – 2026-11-07

- Ship info: the current speed is shown as a number with its unit (km/s) instead of a bar.

## alpha 0.4.25.44 – 2026-11-07

**Package 27 (part 2) – the outfitter rework.**
- Categories → the ship's slots → module families → size · quality tiles → description and value changes;
  buy & fit straight into the slot; a footer with the ship's key values and power.
- A short description for every module family (also in all module tooltips); current speed in the ship info.

## alpha 0.4.25.43 – 2026-11-07

**Package 27 (part 1) – new station concourse.**
- Three columns instead of the tile grid: commander (placeholder) and news; the docked ship with its state and
  the ship services (refuel / repair in one click); the station with faction, economy, balance and its services.
- Waystations offer only market, fuel, repair and hangar (as decided for part 4).

## alpha 0.4.25.42 – 2026-11-07

**Package 26 – station type 0: waystations with landing pads.**
- New small station type in most systems with 2–4 round landing pads instead of hangar bays (S and M ships only).
- Landing and lifting off through an animated hatch; one ship per pad at a time, the others wait.

## alpha 0.4.25.41 – 2026-11-07

- Kanayama-maru market: traders park nearby and send a cargo drone that lands on the runway over the stern,
  picks up the wares, takes off past the bow and flies back; one drone on the runway at a time.

## alpha 0.4.25.40 – 2026-11-07

- Cloak: using a weapon, tool or module ends it (a refused one does not); target locks are allowed while cloaked
  and kept when cloaking.
- New drone module Drone Cloak Emitter (only for ships with a cloaking device, sold by Directorate outfitters):
  the drones become Axiom cloak drones with their own look and cloak together with their ship.

## alpha 0.4.25.39 – 2026-11-07

- Threshold: the black hole goes out under the cloak and ignites again once the ship is fully visible.

## alpha 0.4.25.38 – 2026-11-07

- Threshold: the black hole's ignition flash now really flares up – halo, white-hot centre, rays, the hull lights up.
- Cloak: no more rectangle over the ship – a cyan scan line runs over the hull from stern to bow and the ship fades
  behind it; it shows again bow first.

## alpha 0.4.25.37 – 2026-11-07

- Threshold: the black hole ignites 2.5 s after undocking – a flash of light, the hole grows, then the accretion
  disc forms; it goes out with a flash when docking. It keeps the same orientation whichever way the ship turns.

## alpha 0.4.25.36 – 2026-11-07

- Threshold: a raised bridge at the stern – three stepped decks casting shadows, the cabin on top looking forward
  through a cyan window band; the drone hatch moves to the forward hull.

## alpha 0.4.25.35 – 2026-11-07

- Threshold: the black hole now looks three-dimensional – the accretion disc is tilted towards the camera, its near
  band crosses in front of the hole and its far half is lensed into a bright arc over the top; one side glows hotter.

## alpha 0.4.25.34 – 2026-11-07

**Package 25g – Axiom Astronautics: research and jump ships.**
- Parallax and Threshold: futuristic graphite hulls with cyan light lines; the Threshold's round core holds an
  artificial black hole with a turning accretion disc.
- Sensors +25 %, signature −25 %, power use −15 %, built-in cloaking device.
- Parallax marks systems with undiscovered anomalies on the galaxy map.
- Threshold: wormhole jumps without a gate for exotic matter (new resource from rare anomalies).
- Axiom research ships in Directorate systems. Debug: +10 exotic matter.

## alpha 0.4.25.33 – 2026-11-07

- The Cathedral bundles its crystals too: one lance, one tile; in auto mode the lance takes turns
  between up to six targets.
- Lance balance: each lance carries the damage of its whole 2 s cycle – bundling really gives +30 %
  damage per second.

## alpha 0.4.25.32 – 2026-11-07

- Focus lance: the crystal beams meet between ship and target, charge for a moment, then a thick beam
  burns into the target for about a second.
- Templar and Cathedral: golden spikes slide out and back in now and then.
- Anti-drone pulse: a bar in its module tile shows the next pulse; knocked-out drones crackle with red
  lightning.
- Debug: a hostile pirate drone carrier (debug only).

## alpha 0.4.25.31 – 2026-11-07

**Package 25f – Forge of Return, the Covenant's flying temples.**
- Acolyte, Templar, Cathedral: crimson battlements and crystal batteries around a radiant nave; the
  Cathedral with a rose window, bell towers and a golden halo.
- Focus-crystal lasers (Covenant outfitters and ships only); beam bundling into a focus lance (+30 %).
- Reactor +80 % (Cathedral +120 %), weak hulls, no drone hangars.
- Cathedral: anti-drone pulse (drones drift for 15 s, friend or foe) and auto mode for its lasers.
- Covenant patrols fly Forge ships. Debug: nearby NPC carriers launch their drones.

## alpha 0.4.25.30 – 2026-11-07

- Roadmap: parts 8 (story start in Beyond, packages 55–65) and 9 (feeling and balancing, packages 66–74)
  planned; new package 28a (audio framework) at the start of part 5; loading basics in package 35;
  new principle: a small code review at the end of every part.

## alpha 0.4.25.29 – 2026-11-07

- Concordia: three engine flames – the spine and both flight wings (they move with the wings).

## alpha 0.4.25.28 – 2026-11-07

- Concord stripes pulse much more visibly; the combat light is bigger.
- Drone launch light: a construction-site amber warning light – flashing, with a chase, and beacons at
  the corners of open doors.
- Fix: the Concordia's open doors were hidden under its flight wings – now drones visibly launch from
  and return into open doors.
- Hydraulic struts with joints connect the hull and the deployed flight wings.

## alpha 0.4.25.27 – 2026-11-07

- Concord light effects: the blue stripes pulse; in a fight a bright spot runs along them from bow to
  stern; the Concordia's stripes light up yellow while its drone doors are open.
- Concordia: the flight wings move out and back in space and fold in to dock (the doors move along).
- Drones use the hangar doors in turn, also when launched one by one.

## alpha 0.4.25.26 – 2026-11-07

**Package 25e – Concord Fleetworks, the first faction ships.**
- Demos, Quirinus, Concordia: Assembly drone carriers with visible hangar doors (2 / 4 / 6).
- Drones doubled in every way, control range up to the recon range; own guns half damage; shields +60 %
  with three times the downtime. Concordia: eleven drones in Assembly blue.
- Drones launch from several hangar doors at once and land in the nearest.
- NPC carriers launch their drones in a fight and recall them afterwards.
- Faction ships only at the faction's shipyards and only with standing (Neutral / Friendly / Allied).
- Assembly patrols fly Concord carriers in their own systems (now and then a Goliath).
- Debug: fill the drone hangar. Fix: a hull's shield bonus no longer shortens the shield downtime.

## alpha 0.4.25.25 – 2026-11-07

- Mogura and Iwakudaki: drone hatch moved 3 pixels towards the stern (cleaner fit).

## alpha 0.4.25.24 – 2026-11-07

- Drone hatches: the lower half lies in shadow like the hull, so the crease along the centre line runs
  across the hatch too (also on the sliding panel while it opens).

## alpha 0.4.25.23 – 2026-11-07

- The shut drone hatch is now part of the ship's picture, so it also shows in the hangar, the shipyard
  and the ship menu.

## alpha 0.4.25.22 – 2026-11-07

- Every ship that carries drones has a visible sliding drone hatch (Kanayama-maru: its runway): drones
  rise out of it and land in it; drawn in the maker's colours, sized by ship class.

## alpha 0.4.25.21 – 2026-11-06

- Engine flames sit at the actual drives: the Goliath shows two flames at its arm drives instead of
  one in the middle (ships with a centred drive look as before).

## alpha 0.4.25.20 – 2026-11-06

- Goliath: the arms are hinged at the stern (straight drive sections) and open in space into a round
  arc that carries the pincers far out; they fold in to dock and undock (eight stages).

## alpha 0.4.25.19 – 2026-11-06

- Goliath redesigned as a scorpion: wide-sweeping segmented arms ending in pincers around long cannons,
  a long spiked bow, two slanted red eye-slits as the bridge that glow up and fade, a drone hatch on the spine.
- Citadel gets the armoured-dome bridge; all four bridge designs are kept as variants.
- Ship art scripts are now kept in `tools/art/`.

## alpha 0.4.25.18 – 2026-11-06

- Hadrian design pass: rounded side parts; the Goliath's arms start far aft and arch around the hull,
  with one drive on each arm instead of a main engine.
- Citadel: a big launch platform with a sliding hatch (the S ship rises and lifts off – animation for
  now, the ship comes with part 5) and a small drone hatch – drones rise out of it and land in it.
- Debug menu → Ship: "Citadel: launch from the platform".

## alpha 0.4.25.17 – 2026-11-06

**Package 25d – Hadrian Dynamics.**
- Talon, Maul, Goliath and Citadel: brutalist warships in dark steel with red lights.
- Reflective hull (10/15/20 % of armour damage back to the attacker), +20 % explosive resistance on M/L.
- Weak outside combat: few tool slots, no ore hold, −50 % mining/salvage/analysis, high signature.
- Talon fires rockets and torpedoes faster; Goliath and Citadel with built-in point defence.
- Goliath and Citadel only at military stations and the biggest yards.
- Pirates fly worn, rusty Hadrian copies; Directorate patrols fly Hadrian ships.
- Debug menu: spawn any ship next to you.

## alpha 0.4.25.16 – 2026-11-05

- Empress: the ripples on the pool move at half speed (the glint on the glass dome is unchanged).

## alpha 0.4.25.15 – 2026-11-05

- Studio intro: the d, the title and the brackets stay centred when the window is resized or maximised.

## alpha 0.4.25.14 – 2026-11-05

- Roadmap: plans for parts 5 (Character Update), 6 (New Worlds Discovery Update) and the new part 7
  (The Sky Is Not Enough) taken over from the draft; story moves to part 8, balancing to part 9;
  phases 1 and 2 swapped (story & endgame first, co-op last); new working principles (debug functions
  per package, single player first but co-op-ready, alpha until the end of phase 2).

## alpha 0.4.25.13 – 2026-11-05

- Empress redesigned: narrower window sides and a long park deck under a glass dome between the gold
  stripes – lawn, trees, flowers and a pool with sun loungers; animated pool water and a glint on the dome.

## alpha 0.4.25.12 – 2026-11-05

**Package 25c – Maison Aurelle and passenger transport.**
- Passenger cabins: bulk, business and luxury suites (luxury only in Aurelle ships), with new icons.
- Bulletin board tab "Passengers": transport contracts, paid per passenger and jump, with deadlines;
  failure (late, or ship lost) costs a little standing.
- Four Maison Aurelle ships: Pearl, Boulevard, Opal, Empress – ivory and gold, rows of windows.
- Built-in afterburner (Pearl, Boulevard, Opal); Empress with fast warp, strong shields, half-size cargo
  racks, +25 % luxury pay and white drones with their own shield.
- Aurelle yards only at trade hubs of rich, safe Assembly/Covenant systems; Boulevard liners as NPC traffic.

## alpha 0.4.25.11 – 2026-11-05

- Ship menu: the on-board market has its own tab "Market"; "Industry" and "Market" only show on ships that have a factory / a market.

## alpha 0.4.25.10 – 2026-11-05

- Fix: the warp alignment ring on the ship shows the real time until the warp starts (alignment time plus
  the turn still needed) – it used the jump drive spool time and was full too early on slow KHI ships.
- Kanayama-maru: drones roll down the whole runway one after the other and only break away past the bow.
- Roadmap_Entwurf.md (draft worked on in Claude Chat) is kept out of the repository (.gitignore); the
  screenshot folder is ignored by Godot's importer.

## alpha 0.4.25.9 – 2026-11-05

- Kanayama-maru: the bridge is now the rounded, sloping glass front of the first design, at the front of the rear block.

## alpha 0.4.25.8 – 2026-11-05

- Kanayama-maru redesigned as a carrier: tall rear block with the bridge flush at its front, a flat flight
  deck in front of it (lights, centre line, drone lifts). Drones launch forwards off the deck and land on it.

## alpha 0.4.25.7 – 2026-11-05

**Package 25b – Kanayama-maru, the heavy industry ship.**
- Drone carrier for nine yellow mining drones (+25 % mining, +5 m³), station-grade refinery, prospector.
- Manufacturing takes time everywhere (stations too); jobs are queued and saved.
- On-board factory: modules and drones from the cargo hold.
- On-board market: traders come over and buy at fair prices; big offers attract pirates.
- New ship menu tab "Industry"; icons for factory and market.

## alpha 0.4.25.6 – 2026-11-05

- Intro: the laser shot is now a short, soft zap and quieter (less tiring).

## alpha 0.4.25.5 – 2026-11-05

- New studio intro "dlirius games": the animated d on black with a laser shot per colour bar, the title in
  silver with two brackets; a click slams them together around the d with a hammer-on-iron sound, any key
  skips. The game now starts with scenes/intro.tscn.

## alpha 0.4.25.4 – 2026-11-05

- Fix: the power priority of built-in modules (refinery, prospector) can be set in power management.
- Balancing: the KHI refineries draw twice the power (8 / 16 / 32 MW while on).

## alpha 0.4.25.3 – 2026-11-05

- Fix: the KHI smoke plumes blew inwards across the hull – they now blow outwards from the flank pipes.

## alpha 0.4.25.2 – 2026-11-05

- KHI refinery smoke now sprays in thin plumes sideways out of the exhaust pipes on the flanks instead of out of the stern (looked like a burning engine).

## alpha 0.4.25.1 – 2026-11-05

**Package 25a – Kanayama Heavy Industries mining ships.**
- Manufacturer framework: every hull has a maker; shipyards stock hulls by the maker's rules; mining
  colonies get a small yard (Mogura, Anaguma, Drillhead); the shipyard shows the maker.
- Mogura (S), Anaguma (M), Iwakudaki (L) with built-in ore hold, refinery (switchable, power while on,
  black smoke) and prospector; +10 % mining, slow to turn and to warp. Half the NPC miners fly them.
- Built-in modules are framed in gold and listed in the ship menu and power management.

## alpha 0.4.24.2 – 2026-11-05

**Package 24 – ship manufacturers (planning finished).**
- Seven manufacturers in data/manufacturers.gd, each with its own crest (three new crest shapes, warning
  stripes) and a codex entry with motto, history and planned models.
- The recon radar always shows 10,000 km, independent of the window size; drone control ranges never
  exceed it.

## alpha 0.4.24.1 – 2026-11-05

Package 24 (planning of the manufacturers) is running – this update carries two small changes:
- Hivewright Drone Works now goes by the tag HWD.
- Drones keep out of the radar shadow of colossi: they ignore targets behind one, fly back when they end
  up in a shadow, and steer around colossi.

## alpha 0.4.23.4 – 2026-11-05

- K launches one drone per press (up to the maximum); new action "Launch all drones" without a default key (Settings → Controls).

## alpha 0.4.23.3 – 2026-11-05

- Idle drones fly a symmetric formation: mirrored pairs left and right, an odd one exactly behind on the centre line, same heading as the ship.

## alpha 0.4.23.2 – 2026-11-05

- Ship menu → Modules: new category for the drone hangar equipment (weapon, mining laser, drone module).
- Icons for the drone hangar and the drone modules (also on the Drone Bay tile).

## alpha 0.4.23.1 – 2026-11-05

**Package 23 – drones.** 498 smoke-test checks pass.
- New core slot: Drone Hangar (size 1–9, quality = room); drones out at once by hull (S 1 … L 9).
- Hangar equipment for all drones: weapon (size 1), mining laser (size 1), bonus slot for 8 new drone
  module families.
- Drones with combat / mining / repair roles and behaviours, sealed fuel (about 5 min), 9,000 km
  control range; they really fire and mine; lost when empty or destroyed.
- Drone window at the top left edge, keys K (launch) and P (recall); into the hangar for warps and
  jumps and out again afterwards.
- Drone Bay (Hivewright Drone Works) at every station.
- Test fix: the manual-weapons test no longer fails when its pirate carries a radar jammer.

## alpha 0.4.22.4 – 2026-11-05

- Fix: a newly locked target becomes the active one (modules on the old target turn yellow).
- Fix: modules no longer switch off when their target leaves the sensor range – they wait (orange), the
  target is locked again automatically when it is back (within 60 s) and they fire again.

## alpha 0.4.22.3 – 2026-11-05

- Module tiles: green = active on the current target, yellow = active on another target (out of range is now orange).
- Balancing: all weapon ranges +10 %, sensor ranges +15 %.

## alpha 0.4.22.2 – 2026-11-05

- Tab: ships first, then asteroids, wrecks and anomalies; with nothing selected it starts with the ships again.

## alpha 0.4.22.1 – 2026-11-05

**Package 22 – multi-focus.** 462 smoke-test checks pass.
- Every weapon and tool keeps the target it was switched on against; pressing a running module's key
  moves it to the active target. Lock slots 3–6 by sensor size; T1/T2 labels on tiles, locks, brackets.
- Bigger NPC ships split their fire over several targets.
- Targeting keys: Tab cycles everything in sensor range, V hostile ships, C friendly ships.

## alpha 0.4.21.2 – 2026-11-05

- Power bar: one block per priority group (passive and active no longer split).
- Modules that need no power are in group 0 (no priority buttons, no extra text).

## alpha 0.4.21.1 – 2026-11-05

**Package 21 – power management.** 446 smoke-test checks pass.
- The reactor output is a hard limit; passive modules always draw, weapons and active modules only
  while in use.
- Priority groups 1–4 per module: on an overload group 4 shuts down first, then 3, then 2.
- Ship menu → Modules → POWER MANAGEMENT: output bar per group and the module list with priorities.
- HUD power line (passive + active, groups off); chat messages on shutdown and restart.

## alpha 0.4.20.1 – 2026-11-05

**Package 20 – new module types.** 436 smoke-test checks pass. (From here on the last number counts
the updates within the current package.)
- Shield variants (balanced / capacitive / fast-cycle) and shield downtime for every ship: a shot-down
  shield stays offline (by size, type, quality) and restarts at 50 %.
- Point Defense Turret: shoots down hostile missiles, torpedoes and mines.
- Shield Transfer Beam: charges a friendly ship's shield from your capacitor, shortens its downtime.
- Cargo Scanner (manifests, smugglers' unregistered cargo) and Solar Collector (refuels near the star).
- Mine Launcher with four mine types sold as goods: proximity, timed, jammer, EMP.
- Radar Jammer – also used by pirates against you (radar static, short contact list, shorter locks).

## alpha 0.4.19.19 – 2026-11-05

- Debug menu (Pilot → Contracts): "Escort convoy" with adjustable freighters (1–6) and jumps (1–8) –
  an escort contract from the docked (or nearest) station to a random station exactly that many
  jumps away, accepted at once; the convoy rolls out and waits for you.

## alpha 0.4.19.18 – 2026-11-05

- Formation fix: the pilot's ship no longer lags behind in warp. Followers use the lead's position of
  the current frame (the pilot's ship was updated before the lead), and the lead takes the whole
  formation into warp in the same instant.

## alpha 0.4.19.17 – 2026-11-05

- Debug menu: "Reroll board here" also rerolls the station's faction contracts.

## alpha 0.4.19.16 – 2026-11-05

Formation flight and keyboard controls. 403 smoke-test checks pass.
- Followers fly a fixed V formation behind the lead and keep their slot for the whole warp.
- The lead of your group announces each warp and gate jump in the chat.
- WASD flies the ship (release: stop), the arrow keys pan the camera. Saved camera bindings from older
  versions are reset once.
- Tab selects the nearest hostile ship (again: the next one), B the nearest station within 5,000 km.

## alpha 0.4.19.15 – 2026-11-05

Convoy and group follow-ups, command hotkeys. 397 smoke-test checks pass.
- Group warp: the ship being followed warps at the speed of the slowest ship following it.
- After a pirate attack convoy ships no longer scatter; the convoy holds until no pirate is within its
  recon range and the pilot follows (≤ 8,000 km) or is right next to it (≤ 2,000 km); 2 min timeout.
- Your group (convoy, patrol, followed ship, followers) shows as green tiles at the top left.
- New rebindable hotkeys: R lock/unlock (nearest hostile if nothing selected), Q approach, X warp,
  J jump, G dock, F follow. Buttons show their key in the tooltip.

## alpha 0.4.19.14 – 2026-11-05

Patrol contracts work like convoy escorts now. 386 smoke-test checks pass.
- The contract gets its own patrol group: it starts at the issuing station (rolling out of its bays) or
  at a named gate/field, waits for the pilot (Follow or 3 s within 1,000 km), then flies its rounds.
- Marked green with a PATROL LEAD on combat view, radar and system map; Follow works (also in warp).
- Only flying with that group counts; it is released afterwards; if it is destroyed, the contract fails.
- Test fix: the notorious roaming test starts next to a safer system (was random).

## alpha 0.4.19.13 – 2026-11-04

**Package 19 – module size & quality system** (first package of Teil 4). 379 smoke-test checks pass.
**Old saves cannot be loaded any more** (save version 2) – please start a new game.
- Modules are family + size + quality ("Pulse Laser 2 · C"): 53 families, about 1,700 modules generated
  from size curves and quality factors (D lightest, F heaviest, B as heavy as A).
- Every hull slot has its own maximum size; smaller modules fit bigger slots; hyperdrive size sets the
  jump class.
- Outfitters stock sizes and qualities by station tier, manufacturing rolls the quality, military-grade
  gear is the biggest modules.
- Skiff and Longhaul are sold at shipyards, the Carrion Crow in Pirate Havens.
- Modules tab shows slot maxima and module size/quality; outfitter grouped by family.

## alpha 0.3.18.12 – 2026-11-04

Planning only: slot layouts of all nine current hulls agreed (per-slot sizes, core slots), hyperdrive
size ↔ jump class, Earthworks membership; the NPC-only hulls become buyable (Carrion Crow in Pirate
Havens, Skiff, Longhaul); patrols will fly their own faction's ships once the state manufacturers exist.

## alpha 0.3.18.11 – 2026-11-04

Planning only: the module system design for package 19 is agreed and recorded in the roadmap –
module = family + size + quality, size curves, smaller modules fit bigger slots, quality factors with
mass rules (D lightest, F heaviest, B as heavy as A), per-slot sizes for every ship.

## alpha 0.3.18.10 – 2026-11-04

Planning only (no gameplay change): all open questions of Teil 4 decided and recorded in the roadmap –
module system rebuilt from scratch (weapons size 1–4, slots defined per ship), quality F–A buyable and
S in the endgame, multi-focus as several active targets, drones limited by hangar + bandwidth, mines as
goods, radar jammer used by and against the player, type-0 station services, faction ships from
Neutral (top models Allied) at their own yards, specialised manufacturers starting with "Earthworks"
(today's hulls), about 24 ships, design discussed per manufacturer.

## alpha 0.3.18.9 – 2026-11-04

**Package 18 – Codex.** Teil 3 (NPCs and Factions) is complete. 365 smoke-test checks pass.
- In-game encyclopedia with 45 entries in six categories (Basics, History, Factions, Corporations,
  The Cluster, Technology); faction and corporation entries generated from their data.
- Ship menu tab "Codex"; "Codex" in the main menu shows everything discovered in any game.
- Basics known from the start, the rest unlocks on discovery (first dock, factions met, services used,
  colossi, havens, notorious pirates, raids, ion weapons, warp, gates, mining); "New Codex entry" notice.
- Roadmap: GitHub repository noted in the versioning rules.

## alpha 0.3.18.8 – 2026-11-04

First versioned state (git introduced). Phase 0.5, Teil 3 (NPCs and Factions): packages 10–17 done,
package 18 (Codex) is next. 354 automated smoke-test checks pass.

Content since moving to Claude Code:
- **Package 12 – Reputation per faction:** standing −100…+100 in five tiers; docking, prices, patrols,
  contracts, military gear; pirate standing opens the Pirate Havens; Standing tab in the ship menu.
- **Patrol beats:** patrols fly slow rounds at each waypoint (round stations, through fields).
- **Package 13 – Bounties & law:** bounties issued by the powers, bonds paid at any station of the
  issuer; criminal record per power (Suspect / Wanted / Most Wanted), fines, decay.
- **Package 14 – Pirate archetypes:** Raider, Brawler, Sniper, Ambusher, Leech (new ion weapons), Coward.
- **Package 15 – Notorious pirates:** five named captains with 1–5 stars, growing escorts and bounty,
  wanted posters; station raids by 5-star captains (announcement, hull bar, turrets, ion torpedo,
  offline stations with relief deliveries, red stars, defence reward).
- **Package 16 – World reactions & news:** news ticker (each item once, radio only near you), archive at
  stations, bounty campaigns, distress calls, fleeing traffic, escalation, wrecks for all ships.
- **Package 17 – NPC missions:** faction contracts (escort, patrol, intercept, hunt) and trader escorts at
  trade hubs; convoys of 2–4 freighters with pay per freighter; gathering outside the station, green
  markers, CONVOY LEAD, Follow (also in warp and through gates), warp interdiction and gate ambushes,
  warp announcements in the ticker.
- **Roadmap:** new Teil 4 "Module and Internal Ship Parts Rework" (packages 19–27).
- **Fixes & polish:** clear warning when a jump is not possible (e.g. fuel); debug raid buttons.
