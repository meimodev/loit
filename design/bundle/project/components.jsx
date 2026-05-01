// Components artboards: buttons, icon buttons, inputs, selection, chips, cards,
// list row, avatars, badges, nav, sheets, feedback, progress, empty state, amount display.

function ButtonsBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Button" subtitle="Anatomy: container · (leading icon) · label · (trailing icon) · (loading spinner). One primary per screen. Full-width default on form screens."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Variants · size m · 44pt</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:10, flexWrap:'wrap', marginBottom:24}}>
          <LoitButton variant="primary" label="Save transaction"/>
          <LoitButton variant="secondary" label="Skip for now"/>
          <LoitButton variant="tertiary" label="See all"/>
          <LoitButton variant="destructive" label="Delete"/>
          <LoitButton variant="destructive.solid" label="Delete account"/>
          <LoitButton variant="ghost" label="Cancel"/>
        </div>

        <Label>Sizes · s (36) · m (44) · l (52)</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:10, alignItems:'center', marginBottom:24}}>
          <LoitButton size="s" label="Small"/>
          <LoitButton size="m" label="Medium"/>
          <LoitButton size="l" label="Large"/>
          <LoitButton size="m" leading={<Ico d={icons.plus} size={18} stroke="#fff"/>} label="Add expense"/>
          <LoitButton size="m" variant="secondary" trailing={<Ico d={icons.chevR} size={16}/>} label="Continue"/>
        </div>

        <Label>States</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:10, flexWrap:'wrap', marginBottom:24}}>
          <LoitButton label="Default"/>
          <LoitButton label="Disabled" disabled/>
          <LoitButton label="Loading" loading/>
          <LoitButton variant="secondary" label="Default"/>
          <LoitButton variant="secondary" label="Disabled" disabled/>
        </div>

        <Label>Full-width · form screen footer</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, marginBottom:24, maxWidth:340}}>
          <LoitButton size="l" fullWidth label="Start Pro — Rp85,529/mo"/>
          <div style={{height:8}}/>
          <LoitButton size="l" variant="secondary" fullWidth label="Not now"/>
        </div>

        <div style={{padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Rules</div>
          <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>One primary per screen. Ever.</li>
            <li>Destructive solid is reserved for irreversible confirmations inside a confirm sheet.</li>
            <li>Loading state replaces content with spinner; button width locked to prevent layout shift.</li>
            <li>Disabled: 40% opacity, no other style changes.</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

function IconButtonBoard() {
  const Bubble = ({variant, label}) => {
    let bg='transparent', fg=T.primary;
    if (variant==='tonal') { bg=T.muted; }
    if (variant==='filled') { bg=T.brand; fg='#fff'; }
    return (
      <div style={{textAlign:'center', fontFamily:FONT}}>
        <button style={{width:44, height:44, borderRadius:'50%', background:bg, color:fg, border:'none', cursor:'pointer', display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
          <Ico d={icons.camera} size={22}/>
        </button>
        <div style={{fontSize:11, color:T.secondary, marginTop:6, fontFamily:MONO}}>{label}</div>
      </div>
    );
  };
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Icon Button" subtitle="44×44 hit area · icon centered · optional circular bg on pressed. Requires tooltip and semanticLabel — never icon-only without a label."/>
      <div style={{padding:'24px 32px'}}>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:32}}>
          <Bubble variant="default" label="default"/>
          <Bubble variant="tonal" label="tonal"/>
          <Bubble variant="filled" label="filled"/>
        </div>
      </div>
    </div>
  );
}

function InputsBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Text Input" subtitle="Label above the field (no floating labels). Error text announced on appearance. Autofill hints set appropriately."/>
      <div style={{padding:'24px 32px'}}>
        <Label>States</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'grid', gridTemplateColumns:'1fr 1fr', gap:20, marginBottom:24}}>
          <LoitInput label="Email" placeholder="you@example.com"/>
          <LoitInput label="Email" value="maria@gmail.com" state="focused"/>
          <LoitInput label="Email" value="maria@gmail.com"/>
          <LoitInput label="Email" value="maria@" state="error" error="Enter a valid email address."/>
          <LoitInput label="Account name" value="Maria Kurniawan" state="disabled"/>
          <LoitInput label="Referral code" placeholder="Optional" helper="Earn 1 month of Pro when your friend upgrades."/>
        </div>

        <Label>Sizes · s (36) · m (44) · l (52)</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:20, marginBottom:24}}>
          <LoitInput size="s" label="Inline filter" placeholder="Search merchant"/>
          <LoitInput size="m" label="Default" placeholder="Merchant"/>
          <LoitInput size="l" label="Hero" placeholder="Name on account"/>
        </div>

        <Label>Amount Input · specialized</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'grid', gridTemplateColumns:'1fr 1fr', gap:20}}>
          <LoitInput size="l" label="Amount"
            leading={<span style={{fontSize:16, fontWeight:600, color:T.secondary}}>Rp</span>}
            value="85,000"
            trailing={<span style={{padding:'4px 10px', background:T.muted, borderRadius:999, fontSize:12, fontWeight:600}}>IDR ▾</span>}
          />
          <LoitInput size="l" label="Amount"
            leading={<span style={{fontSize:16, fontWeight:600, color:T.secondary}}>$</span>}
            value="4.99"
            trailing={<span style={{padding:'4px 10px', background:T.muted, borderRadius:999, fontSize:12, fontWeight:600}}>USD ▾</span>}
          />
        </div>

        <div style={{marginTop:22, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Amount Input rules</div>
          <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Triggers numeric keypad (<code style={{fontFamily:MONO, fontSize:12}}>TextInputType.numberWithOptions(decimal: true)</code>).</li>
            <li>Formats on blur using locale-aware grouping (Rp85,000 / $85.00).</li>
            <li>Currency selector as trailing dropdown-chip — tap opens currency picker sheet.</li>
            <li>Negative amounts disallowed in expense context — sign is implicit.</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

function SelectionBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Selection Controls" subtitle="Checkbox, radio, toggle. All have a 44×44 invisible tap area regardless of visual size."/>
      <div style={{padding:'24px 32px'}}>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:28, fontFamily:FONT}}>
          <div>
            <Label>Checkbox · 20×20 · radius.xs</Label>
            <div style={{display:'flex', flexDirection:'column', gap:12}}>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Checkbox checked={false}/><span style={{fontSize:14}}>Unchecked</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Checkbox checked={true}/><span style={{fontSize:14}}>Checked</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center', opacity:0.4}}><Checkbox checked={false}/><span style={{fontSize:14}}>Disabled</span></label>
            </div>
          </div>
          <div>
            <Label>Radio · 20×20 · radius.full</Label>
            <div style={{display:'flex', flexDirection:'column', gap:12}}>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Radio checked={false}/><span style={{fontSize:14}}>Monthly</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Radio checked={true}/><span style={{fontSize:14}}>Yearly — 2 months free</span></label>
            </div>
          </div>
          <div>
            <Label>Toggle · 48×28 · radius.full</Label>
            <div style={{display:'flex', flexDirection:'column', gap:12}}>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Toggle on={true}/><span style={{fontSize:14}}>Biometric lock</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Toggle on={false}/><span style={{fontSize:14}}>Blur amounts</span></label>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ChipsBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Chip" subtitle="Height 32 · radius.full · label.m · space.4 horizontal padding. Used for filter chips, category tags, currency tags, room member pills."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Variants</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:8, flexWrap:'wrap', marginBottom:24}}>
          <LoitChip label="Default"/>
          <LoitChip label="Selected" selected/>
          <LoitChip label="Outline" variant="outline"/>
          <LoitChip label="Bali Trip" dismiss/>
        </div>

        <Label>Filter Row · transaction log</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, marginBottom:24}}>
          <div style={{display:'flex', gap:8, overflow:'auto'}}>
            <LoitChip label="All" selected/>
            <LoitChip label="This month"/>
            <LoitChip label="Dining" leading={<Ico d={icons.utensils} size={14}/>}/>
            <LoitChip label="Groceries" leading={<Ico d={icons.basket} size={14}/>}/>
            <LoitChip label="Transport" leading={<Ico d={icons.car} size={14}/>}/>
            <LoitChip label="IDR"/>
            <LoitChip label="USD"/>
          </div>
        </div>

        <Label>Input / dismissible</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:8, flexWrap:'wrap'}}>
          <LoitChip label="Apartment 4B" dismiss leading={<Avatar size={18} initials="A" color={T.room1}/>}/>
          <LoitChip label="Bali Trip" dismiss leading={<Avatar size={18} initials="B" color={T.room3}/>}/>
          <LoitChip label="Maria" dismiss leading={<Avatar size={18} initials="M" color={T.room5}/>}/>
        </div>
      </div>
    </div>
  );
}

function CardBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Card" subtitle="Container · optional header (title + action) · content · optional footer. Max one primary action inside a card."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Variants</Label>
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:16, marginBottom:24}}>
          <LoitCard>
            <div style={{fontSize:12, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT}}>Default · elevation.0</div>
            <div style={{fontSize:17, fontWeight:600, color:T.primary, fontFamily:FONT, marginTop:6}}>November spending</div>
            <div style={{fontSize:40, fontWeight:600, color:T.primary, fontFamily:FONT, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4, marginTop:10}}>Rp 4.235.000</div>
            <div style={{fontSize:12, color:T.secondary, fontFamily:FONT, marginTop:6}}>↓ 12% vs October</div>
          </LoitCard>
          <LoitCard raised>
            <div style={{fontSize:12, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT}}>Raised · elevation.1</div>
            <div style={{fontSize:17, fontWeight:600, color:T.primary, fontFamily:FONT, marginTop:6}}>Apartment 4B</div>
            <div style={{fontSize:13, color:T.secondary, fontFamily:FONT, marginTop:2}}>3 members · 2 expenses today</div>
            <div style={{marginTop:12, display:'flex', justifyContent:'space-between', alignItems:'center'}}>
              <AvatarStack members={[{initials:'A',color:T.room1},{initials:'M',color:T.room4},{initials:'R',color:T.room3}]}/>
              <div style={{fontSize:16, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', fontFamily:FONT}}>Rp 1.240.000</div>
            </div>
          </LoitCard>
          <LoitCard status="warning">
            <div style={{fontSize:12, fontWeight:600, color:'#A87820', letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT, marginLeft:8}}>Status · warning</div>
            <div style={{fontSize:15, fontWeight:600, color:T.primary, fontFamily:FONT, marginTop:4, marginLeft:8}}>You're 80% through your Dining budget</div>
            <div style={{fontSize:13, color:T.secondary, fontFamily:FONT, marginTop:4, marginLeft:8}}>Rp 1.600.000 of Rp 2.000.000</div>
          </LoitCard>
          <LoitCard status="danger">
            <div style={{fontSize:12, fontWeight:600, color:'#9D332E', letterSpacing:0.4, textTransform:'uppercase', fontFamily:FONT, marginLeft:8}}>Status · danger</div>
            <div style={{fontSize:15, fontWeight:600, color:T.primary, fontFamily:FONT, marginTop:4, marginLeft:8}}>Transport budget exceeded</div>
            <div style={{fontSize:13, color:T.secondary, fontFamily:FONT, marginTop:4, marginLeft:8}}>Rp 1.250.000 of Rp 1.000.000 · 125%</div>
          </LoitCard>
        </div>
      </div>
    </div>
  );
}

function ListRowBoard() {
  const rows = [
    ['Warung Sari Rasa','Dining','Today','Rp 85.000', false, false],
    ['Shell Station Kemang','Transport','Today','Rp 150.000', true, false],
    ['Alfamart','Groceries','Yesterday','Rp 42.500', true, true],
    ['Apple Music','Entertainment','Mon 11 Nov','$10.99', false, false],
    ['Halodoc · Consultation','Health','Sun 10 Nov','Rp 90.000', false, false],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="List Row · Transaction Row" subtitle="The most-rendered component in LOIT. Row height min 64 · leading 40×40 category circle · title body.l 500 · subtitle body.m secondary · trailing amount.default tabular."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Canonical Rows · grouped by day</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, overflow:'hidden', marginBottom:24}}>
          <div style={{padding:'12px 16px', fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, fontFamily:FONT, background:T.muted}}>Today · 12 Nov</div>
          {rows.slice(0,2).map((r,i) => (
            <TxRow key={i} merchant={r[0]} cat={r[1]} date={r[2]} amount={r[3]} receipt={r[4]} aiScanned={r[5]} last={i===1}/>
          ))}
          <div style={{padding:'12px 16px', fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, fontFamily:FONT, background:T.muted, borderTop:`1px solid ${T.bSubtle}`}}>Yesterday · 11 Nov</div>
          {rows.slice(2,3).map((r,i) => (
            <TxRow key={i} merchant={r[0]} cat={r[1]} date={r[2]} amount={r[3]} receipt={r[4]} aiScanned={r[5]} last/>
          ))}
          <div style={{padding:'12px 16px', fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, fontFamily:FONT, background:T.muted, borderTop:`1px solid ${T.bSubtle}`}}>Earlier</div>
          {rows.slice(3).map((r,i) => (
            <TxRow key={i} merchant={r[0]} cat={r[1]} date={r[2]} amount={r[3]} receipt={r[4]} aiScanned={r[5]} last={i===1}/>
          ))}
        </div>

        <Label>States</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, overflow:'hidden', marginBottom:16}}>
          <TxRow merchant="Default" cat="Dining" date="Today" amount="Rp 85.000"/>
          <TxRow merchant="Selected (multi-select)" cat="Transport" date="Today" amount="Rp 150.000" selected/>
          <TxRow merchant="With receipt + AI-scanned" cat="Groceries" date="Today" amount="Rp 42.500" receipt aiScanned last/>
        </div>

        <div style={{padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Interactions</div>
          <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Tap → detail screen</li>
            <li>Long-press → quick menu (recategorize, edit, delete)</li>
            <li>Swipe-left → destructive + edit actions</li>
            <li>Swipe-right → reserved, none in v1</li>
            <li>Divider: 1px border.subtle between rows, no divider before first row or after last</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

function AvatarBadgeBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Avatar, Badge & Tag" subtitle="Avatars always circular. Generated initial avatars use one of 8 room accents deterministically. Badges pair color with a second signal."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Avatar Sizes · 20 / 28 / 40 / 56 / 96</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:24, alignItems:'flex-end', marginBottom:24}}>
          {[20,28,40,56,96].map(s => (
            <div key={s} style={{textAlign:'center'}}>
              <Avatar size={s} initials="M" color={T.brand}/>
              <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>{s}pt</div>
            </div>
          ))}
        </div>

        <Label>Initial Avatars · 8 room accents</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:16, marginBottom:24}}>
          {[['A',T.room1],['M',T.room2],['R',T.room3],['S',T.room4],['D',T.room5],['K',T.room6],['L',T.room7],['P',T.room8]].map(([i,c]) => (
            <Avatar key={i+c} size={40} initials={i} color={c}/>
          ))}
        </div>

        <Label>Avatar Stack · -8pt overlap · 2px surface.default ring</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:24, alignItems:'center', marginBottom:24}}>
          <AvatarStack members={[{initials:'A',color:T.room1},{initials:'M',color:T.room4}]}/>
          <AvatarStack members={[{initials:'A',color:T.room1},{initials:'M',color:T.room4},{initials:'R',color:T.room3},{initials:'S',color:T.room5}]}/>
          <AvatarStack members={[{initials:'A',color:T.room1},{initials:'M',color:T.room4},{initials:'R',color:T.room3},{initials:'S',color:T.room5},{initials:'x'},{initials:'y'},{initials:'z'}]}/>
        </div>

        <Label>Badge & Tag</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:20, alignItems:'center', fontFamily:FONT}}>
          <div style={{textAlign:'center'}}>
            <div style={{width:40, height:40, borderRadius:'50%', background:T.muted, display:'inline-flex', alignItems:'center', justifyContent:'center', position:'relative'}}>
              <Ico d={icons.settings} size={18}/>
              <div style={{position:'absolute', top:4, right:4, width:8, height:8, borderRadius:'50%', background:'#C5443E'}}/>
            </div>
            <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>Badge (dot)</div>
          </div>
          <div style={{textAlign:'center'}}>
            <div style={{width:40, height:40, borderRadius:'50%', background:T.muted, display:'inline-flex', alignItems:'center', justifyContent:'center', position:'relative'}}>
              <Ico d={icons.receipt} size={18}/>
              <div style={{position:'absolute', top:-4, right:-4, minWidth:18, height:18, borderRadius:999, background:'#C5443E', color:'#fff', fontSize:11, fontWeight:600, padding:'0 5px', display:'inline-flex', alignItems:'center', justifyContent:'center'}}>3</div>
            </div>
            <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>Badge (count)</div>
          </div>
          <div style={{textAlign:'center'}}>
            <span style={{height:20, display:'inline-flex', alignItems:'center', padding:'0 6px', background:T.teal100, color:T.teal800, fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', borderRadius:4}}>AI-scanned</span>
            <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>Tag · label.s</div>
          </div>
          <div style={{textAlign:'center'}}>
            <span style={{height:20, display:'inline-flex', alignItems:'center', padding:'0 6px', background:T.ochre100, color:T.ochre700, fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', borderRadius:4}}>Pro</span>
            <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>Tag · Pro</div>
          </div>
          <div style={{textAlign:'center'}}>
            <span style={{height:20, display:'inline-flex', alignItems:'center', padding:'0 6px', background:T.muted, color:T.secondary, fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', borderRadius:4}}>Archived</span>
            <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:6}}>Tag · Archived</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function NavBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Navigation" subtitle="Bottom tab bar with exactly 4 tabs — Scan is center-lifted as a 56×56 circular FAB-style. No hamburger menus anywhere. Tab bar always visible on top-level screens, hidden on modal/detail."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Bottom Tab Bar · 56 + safe area</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, padding:32, marginBottom:24, fontFamily:FONT}}>
          <div style={{maxWidth:360, margin:'0 auto', position:'relative'}}>
            <div style={{height:80, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, boxShadow:'0 1px 2px rgba(17,22,19,0.04)', display:'flex', borderRadius:12, position:'relative'}}>
              {[['Home','home',true],['Scan','camera',false,true],['Rooms','users',false],['Settings','settings',false]].map(([name, icon, active, fab]) => (
                <div key={name} style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', position:fab?'relative':undefined}}>
                  {fab ? (
                    <div style={{position:'absolute', top:-8, width:56, height:56, borderRadius:'50%', background:T.brand, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', boxShadow:'0 4px 12px rgba(17,22,19,0.12)'}}>
                      <Ico d={icons.camera} size={24}/>
                    </div>
                  ) : (
                    <>
                      <div style={{color: active?T.brand:T.tertiary}}><Ico d={icons[icon]} size={24}/></div>
                      <div style={{fontSize:11, fontWeight:600, color: active?T.brand:T.tertiary, marginTop:4, letterSpacing:0.4}}>{name}</div>
                    </>
                  )}
                  {fab && <div style={{fontSize:11, fontWeight:600, color:T.tertiary, marginTop:30, letterSpacing:0.4}}>Scan</div>}
                </div>
              ))}
            </div>
          </div>
        </div>

        <Label>App Bar · 56 + safe area</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, marginBottom:24}}>
          <div style={{maxWidth:360, margin:'0 auto'}}>
            <div style={{height:56, display:'flex', alignItems:'center', padding:'0 8px', background:T.surface, borderRadius:12, border:`1px solid ${T.bSubtle}`, fontFamily:FONT, marginBottom:10}}>
              <button style={{width:44, height:44, borderRadius:'50%', background:'transparent', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.chevL} size={24}/></button>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, marginLeft:4, flex:1, letterSpacing:-0.15}}>Transactions</div>
              <button style={{width:44, height:44, borderRadius:'50%', background:'transparent', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.search} size={22}/></button>
            </div>
            <div style={{padding:'14px 16px', background:T.surface, borderRadius:12, border:`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary}}>Large variant · 96</div>
              <div style={{fontSize:24, fontWeight:600, color:T.primary, marginTop:6, letterSpacing:-0.2}}>Bali Trip</div>
            </div>
          </div>
        </div>

        <Label>Segmented Control · height 36</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:16, fontFamily:FONT}}>
          <div style={{height:36, background:T.muted, borderRadius:12, padding:2, display:'inline-flex', gap:2}}>
            {['Feed','Budget','Reports'].map((s,i) => (
              <div key={s} style={{padding:'0 14px', borderRadius:10, display:'inline-flex', alignItems:'center', fontSize:14, fontWeight:600, color:i===0?T.primary:T.secondary, background:i===0?T.surface:'transparent', boxShadow:i===0?'0 1px 2px rgba(17,22,19,0.04)':'none', letterSpacing:0.2}}>{s}</div>
            ))}
          </div>
          <div style={{height:36, background:T.muted, borderRadius:12, padding:2, display:'inline-flex', gap:2}}>
            {['By Category','By Merchant','Trend','Calendar'].map((s,i) => (
              <div key={s} style={{padding:'0 12px', borderRadius:10, display:'inline-flex', alignItems:'center', fontSize:13, fontWeight:600, color:i===2?T.primary:T.secondary, background:i===2?T.surface:'transparent', boxShadow:i===2?'0 1px 2px rgba(17,22,19,0.04)':'none', letterSpacing:0.2}}>{s}</div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function SheetsBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Sheets & Modals" subtitle="Bottom sheets are primary. Modals reserved for high-friction confirmations only (delete account, sign out from all devices)."/>
      <div style={{padding:'24px 32px', display:'grid', gridTemplateColumns:'1fr 1fr', gap:20}}>
        <div>
          <Label>Bottom Sheet</Label>
          <div style={{background:'rgba(0,0,0,0.40)', borderRadius:16, padding:'80px 20px 0', height:440, fontFamily:FONT, position:'relative', overflow:'hidden'}}>
            <div style={{background:T.surface, borderRadius:'24px 24px 0 0', boxShadow:'0 12px 32px rgba(17,22,19,0.12)', padding:'16px 20px 24px', minHeight:320}}>
              <div style={{width:36, height:4, background:T.bStrong, borderRadius:999, margin:'0 auto 16px'}}/>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Pick a category</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:4}}>This won't change past transactions.</div>
              <div style={{marginTop:16, display:'flex', flexDirection:'column'}}>
                {[['Dining','utensils','#F2A85C', true],['Groceries','basket','#2F8F5E'],['Transport','car','#3E7AC5'],['Shopping','bag','#B15FC0']].map(([name, icon, tint, sel]) => (
                  <div key={name} style={{display:'flex', alignItems:'center', gap:12, padding:'12px 0', borderBottom:`1px solid ${T.bSubtle}`}}>
                    <div style={{width:40, height:40, borderRadius:'50%', background:tint+'1F', color:tint, display:'inline-flex', alignItems:'center', justifyContent:'center'}}>
                      <Ico d={icons[icon]} size={20}/>
                    </div>
                    <div style={{flex:1, fontSize:16, fontWeight:500, color:T.primary}}>{name}</div>
                    {sel && <div style={{color:T.brand}}><Ico d={icons.check} size={20}/></div>}
                  </div>
                ))}
              </div>
            </div>
          </div>
          <div style={{marginTop:8, fontSize:12, color:T.secondary, fontFamily:FONT, lineHeight:'18px'}}>Handle bar 36×4 · 24pt top radius · snap peek 30% / full 85%. <code style={{fontFamily:MONO, fontSize:11}}>motion.emphasized</code> rise with scrim fade.</div>
        </div>
        <div>
          <Label>Confirmation Sheet · destructive pattern</Label>
          <div style={{background:'rgba(0,0,0,0.40)', borderRadius:16, padding:'140px 20px 0', height:440, fontFamily:FONT, position:'relative', overflow:'hidden'}}>
            <div style={{background:T.surface, borderRadius:'24px 24px 0 0', padding:'16px 20px 24px', minHeight:260}}>
              <div style={{width:36, height:4, background:T.bStrong, borderRadius:999, margin:'0 auto 16px'}}/>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Delete transaction?</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px'}}>This can't be undone. The receipt photo will also be deleted.</div>
              <div style={{marginTop:12, padding:12, background:'#FBEAE9', borderRadius:12, display:'flex', gap:10, alignItems:'flex-start'}}>
                <div style={{color:'#9D332E'}}><Ico d={icons.alert} size={18}/></div>
                <div style={{fontSize:13, color:'#9D332E'}}>Shared room members will see this as removed immediately.</div>
              </div>
              <div style={{display:'flex', gap:10, marginTop:20}}>
                <LoitButton size="m" variant="secondary" label="Cancel" fullWidth/>
                <LoitButton size="m" variant="destructive.solid" label="Delete" fullWidth/>
              </div>
            </div>
          </div>
          <div style={{marginTop:8, fontSize:12, color:T.secondary, fontFamily:FONT, lineHeight:'18px'}}>Destructive default-focuses Cancel — user must consciously reach for the destructive side.</div>
        </div>
      </div>
    </div>
  );
}

function FeedbackBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Feedback · Toast, Snackbar, Banner" subtitle="Toast auto-dismiss 3s (top). Snackbar auto-dismiss 5s with action (bottom) for undo. Banner persistent for offline, expiry warning."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Toast · surface.inverse · top</Label>
        <div style={{background:T.canvas, padding:20, borderRadius:12, marginBottom:20, border:`1px solid ${T.bSubtle}`}}>
          <div style={{maxWidth:440, padding:'14px 16px', background:T.n900, color:'#fff', borderRadius:12, fontSize:14, fontWeight:500, fontFamily:FONT, display:'flex', alignItems:'center', gap:10, boxShadow:'0 4px 12px rgba(17,22,19,0.08)'}}>
            <Ico d={icons.check} size={18} stroke={T.teal300}/>
            <span>Saved.</span>
          </div>
        </div>

        <Label>Snackbar · with undo action · bottom</Label>
        <div style={{background:T.canvas, padding:20, borderRadius:12, marginBottom:20, border:`1px solid ${T.bSubtle}`}}>
          <div style={{maxWidth:480, padding:'14px 16px', background:T.n900, color:'#fff', borderRadius:12, fontSize:14, fontFamily:FONT, display:'flex', alignItems:'center', justifyContent:'space-between', gap:16, boxShadow:'0 4px 12px rgba(17,22,19,0.08)'}}>
            <span>Transaction deleted.</span>
            <button style={{background:'transparent', border:'none', color:T.ochre300, fontSize:14, fontWeight:600, cursor:'pointer', letterSpacing:0.3}}>UNDO</button>
          </div>
        </div>

        <Label>Banners · persistent · status surface</Label>
        <div style={{display:'grid', gap:10, marginBottom:20}}>
          {[
            ['success','#E8F5EC','#227549','check','Synced. 4 transactions synced.'],
            ['warning','#FDF4E0','#A87820','alert',"You're 80% through your Dining budget."],
            ['danger','#FBEAE9','#9D332E','alert','Transport budget exceeded.'],
            ['info','#E6EEF8','#2F5E99','info',"You're offline. Personal tracking still works."],
          ].map(([k,bg,fg,ico,copy]) => (
            <div key={k} style={{padding:'14px 16px', background:bg, color:fg, borderRadius:12, display:'flex', alignItems:'center', gap:12, fontFamily:FONT}}>
              <Ico d={icons[ico]} size={20}/>
              <div style={{flex:1, fontSize:14, fontWeight:500}}>{copy}</div>
              <button style={{background:'transparent', border:'none', color:fg, fontSize:13, fontWeight:600, cursor:'pointer'}}>Details</button>
              <button style={{background:'transparent', border:'none', color:fg, cursor:'pointer', width:24, height:24, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.x} size={16}/></button>
            </div>
          ))}
        </div>

        <Label>Modal (center dialog) · reserved for blocking decisions</Label>
        <div style={{background:'rgba(0,0,0,0.40)', borderRadius:16, padding:'40px 40px', fontFamily:FONT, display:'flex', justifyContent:'center'}}>
          <div style={{width:320, background:T.surface, borderRadius:16, padding:20, boxShadow:'0 12px 32px rgba(17,22,19,0.12)'}}>
            <div style={{width:40, height:40, borderRadius:'50%', background:'#FBEAE9', color:'#9D332E', display:'inline-flex', alignItems:'center', justifyContent:'center', marginBottom:12}}>
              <Ico d={icons.alert} size={22}/>
            </div>
            <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Sign out from all devices?</div>
            <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px'}}>You'll need to sign back in on each device.</div>
            <div style={{display:'flex', gap:10, marginTop:20}}>
              <LoitButton size="m" variant="ghost" label="Cancel" fullWidth/>
              <LoitButton size="m" variant="destructive.solid" label="Sign out" fullWidth/>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ProgressBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Progress & Loading" subtitle="Budget bar, circular progress, skeletons. Skeletons for any structural load > 300ms — spinners only for indeterminate operations (scanning, payment)."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Budget Bar · height 8 · radius.full · semantic fill</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, fontFamily:FONT, marginBottom:24}}>
          {[['Under budget · <70%',48,'Rp 960,000 of Rp 2,000,000'],['Warning · 70–99%',82,'Rp 1,640,000 of Rp 2,000,000'],['Over budget · 100%+',125,'Rp 1,250,000 of Rp 1,000,000']].map(([n,p,sub]) => (
            <div key={n} style={{marginBottom:18}}>
              <div style={{display:'flex', justifyContent:'space-between', marginBottom:8}}>
                <div style={{fontSize:14, fontWeight:500, color:T.primary}}>{n}</div>
                <div style={{fontSize:14, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>{p}%</div>
              </div>
              <BudgetBar pct={p}/>
              <div style={{fontSize:12, color:T.secondary, marginTop:6, fontVariantNumeric:'tabular-nums'}}>{sub}</div>
            </div>
          ))}
        </div>

        <Label>Circular Progress · indeterminate</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, display:'flex', gap:32, alignItems:'center', fontFamily:FONT, marginBottom:24}}>
          {[48,24].map(s => (
            <div key={s} style={{textAlign:'center'}}>
              <div style={{width:s, height:s, borderRadius:'50%', border:`3px solid ${T.muted}`, borderTopColor:T.brand, display:'inline-block', animation:'loit-spin 1s linear infinite'}}/>
              <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:8}}>{s}pt</div>
            </div>
          ))}
          <div style={{flex:1}}>
            <div style={{fontSize:14, color:T.secondary}}>Used for scanning in progress, payment processing. <code style={{fontFamily:MONO, fontSize:12}}>action.primary.default</code> stroke, 3px width.</div>
          </div>
        </div>

        <Label>Skeleton · shimmer loop 1400ms</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, fontFamily:FONT}}>
          {[1,2,3].map(i => (
            <div key={i} style={{display:'flex', gap:12, alignItems:'center', padding:'12px 4px', borderBottom:i===3?'none':`1px solid ${T.bSubtle}`}}>
              <div className="loit-skel" style={{width:40, height:40, borderRadius:'50%'}}/>
              <div style={{flex:1}}>
                <div className="loit-skel" style={{height:14, width:'60%', borderRadius:4}}/>
                <div className="loit-skel" style={{height:12, width:'40%', borderRadius:4, marginTop:6}}/>
              </div>
              <div className="loit-skel" style={{height:16, width:80, borderRadius:4}}/>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function EmptyStateBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Empty State" subtitle="Illustration 120×120 · title.m · body.m secondary · primary CTA. Every list and data view has a designed empty state. No blank screens anywhere."/>
      <div style={{padding:'24px 32px'}}>
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:20}}>
          {[
            {ill:'receipt', title:'No expenses yet', body:'Snap your first receipt or add one manually.', cta:'Scan a receipt'},
            {ill:'users', title:'Rooms are for friends, trips, households', body:'Create a room or join with an invite link.', cta:'Create room'},
            {ill:'check', title:'Set a monthly goal', body:"See how you're tracking across your top categories.", cta:'Add budget'},
          ].map((s,i) => (
            <div key={i} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, padding:32, textAlign:'center', fontFamily:FONT, display:'flex', flexDirection:'column', alignItems:'center'}}>
              <div style={{width:120, height:120, borderRadius:16, background:`repeating-linear-gradient(135deg, ${T.teal50} 0 8px, ${T.surface} 8px 16px)`, display:'inline-flex', alignItems:'center', justifyContent:'center', marginBottom:20, border:`1px dashed ${T.bDefault}`}}>
                <div style={{color:T.brand}}><Ico d={icons[s.ill]} size={40} sw={1.5}/></div>
              </div>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>{s.title}</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px', maxWidth:240}}>{s.body}</div>
              <div style={{marginTop:20}}>
                <LoitButton size="m" label={s.cta}/>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function AmountDisplayBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Amount Display" subtitle="Structural component for rendering money with correct formatting, sign handling, and optional delta indication."/>
      <div style={{padding:'24px 32px', fontFamily:FONT}}>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:32, marginBottom:20}}>
          <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:10}}>Hero · dashboard</div>
          <div style={{fontSize:40, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4}}>Rp 4.235.000</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:6, display:'flex', alignItems:'center', gap:8}}>
            <span style={{display:'inline-flex', alignItems:'center', gap:4, padding:'4px 8px', background:'#E8F5EC', color:'#227549', borderRadius:999, fontSize:12, fontWeight:600}}>
              <Ico d={icons.arrowDown} size={12}/> 12%
            </span>
            <span>vs October</span>
          </div>
        </div>

        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:20, marginBottom:20}}>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20}}>
            <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:8}}>Large · card summary</div>
            <div style={{fontSize:24, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 1.240.000</div>
            <div style={{fontSize:12, color:T.secondary, marginTop:4}}>home currency equivalent · $78.42</div>
          </div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20}}>
            <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:8}}>Default · list row</div>
            <div style={{fontSize:16, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>Rp 85.000</div>
            <div style={{fontSize:14, fontWeight:500, color:T.secondary, fontVariantNumeric:'tabular-nums', marginTop:4}}>Inline · Yesterday · 14.30</div>
          </div>
        </div>

        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20}}>
          <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:10}}>Signed & multi-currency</div>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:20, fontVariantNumeric:'tabular-nums'}}>
            <div>
              <div style={{fontSize:11, color:T.tertiary}}>Negative · minus sign</div>
              <div style={{fontSize:24, fontWeight:600, color:'#C5443E'}}>−Rp 12.000</div>
            </div>
            <div>
              <div style={{fontSize:11, color:T.tertiary}}>Positive delta</div>
              <div style={{fontSize:24, fontWeight:600, color:'#2F8F5E'}}>+Rp 420.000</div>
            </div>
            <div>
              <div style={{fontSize:11, color:T.tertiary}}>USD · 2 decimals</div>
              <div style={{fontSize:24, fontWeight:600, color:T.primary}}>$ 4.99</div>
            </div>
          </div>
        </div>

        <div style={{marginTop:22, padding:16, background:T.muted, borderRadius:12}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Delta chip rules</div>
          <div style={{fontSize:13, color:T.secondary, lineHeight:'20px'}}>
            <code style={{fontFamily:MONO, fontSize:12}}>↑ 12%</code> or <code style={{fontFamily:MONO, fontSize:12}}>↓ 12%</code>, body.s, colored semantically — <b>up = danger</b> in spending context, <b>success</b> in income; reversed in budget context.
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {ButtonsBoard, IconButtonBoard, InputsBoard, SelectionBoard, ChipsBoard, CardBoard, ListRowBoard, AvatarBadgeBoard, NavBoard, SheetsBoard, FeedbackBoard, ProgressBoard, EmptyStateBoard, AmountDisplayBoard});
