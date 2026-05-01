// Foundation artboards: principles, colors, type, space, radius, elevation, motion, iconography, imagery

function PrinciplesBoard() {
  const sysPrinciples = [
    ['01','Tokens are the source of truth','No hex values, pixel values, or duration numbers appear in component specs or Flutter code. They reference tokens.'],
    ['02','Components are closed, not clever','A component exposes a finite set of variants and states. If a new need doesn\'t fit, a new component is proposed — not a new "extra" prop.'],
    ['03','One way to do a thing','If there are two ways to show a confirmation, we pick one and retire the other. Choice inside the system is a bug.'],
    ['04','Consistency > novelty','A component added for one screen is reusable for twenty. If it can\'t be reused, it doesn\'t belong in the system.'],
    ['05','Accessibility is a token, not a toggle','Contrast, tap size, and focus are baked into tokens and components — you cannot assemble an inaccessible LOIT screen from these parts.'],
  ];
  const uxPrinciples = [
    ['01','Personal before shared','The default surface is always "My Finances." Rooms exist but never intrude.'],
    ['02','One screen, one job','Each screen has exactly one primary action. If a screen has two, split it.'],
    ['03','Show the money, hide the machinery','Amounts are the hero. Database IDs, sync states, and infra never appear in copy.'],
    ['04','Progressive disclosure','Free-tier users never see a Pro-only field grayed out in their main flow — upgrade prompts surface contextually at the point of value.'],
    ['05','Destructive and financial actions require a pause','Every irreversible action has a confirmation moment with a clear undo or a clear "this cannot be undone" signal.'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px', minHeight:'100%'}}>
      <Header title="Principles" subtitle="Split bills, not friendships. Five system principles govern the design system itself; five product principles govern every UX decision."/>
      <div style={{padding:'28px 32px', display:'grid', gridTemplateColumns:'1fr 1fr', gap:32}}>
        <div>
          <Label>System Principles</Label>
          {sysPrinciples.map(([n,t,d]) => (
            <div key={n} style={{padding:'18px 0', borderBottom:`1px solid ${T.bSubtle}`}}>
              <div style={{display:'flex', gap:14}}>
                <div style={{fontSize:13, fontWeight:600, color:T.brand, fontFamily:MONO, width:24, flexShrink:0}}>{n}</div>
                <div>
                  <div style={{fontSize:17, fontWeight:600, color:T.primary, fontFamily:FONT, letterSpacing:-0.1}}>{t}</div>
                  <div style={{fontSize:14, color:T.secondary, fontFamily:FONT, marginTop:6, lineHeight:'20px'}}>{d}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
        <div>
          <Label>Product UX Principles</Label>
          {uxPrinciples.map(([n,t,d]) => (
            <div key={n} style={{padding:'18px 0', borderBottom:`1px solid ${T.bSubtle}`}}>
              <div style={{display:'flex', gap:14}}>
                <div style={{fontSize:13, fontWeight:600, color:T.accent, fontFamily:MONO, width:24, flexShrink:0}}>{n}</div>
                <div>
                  <div style={{fontSize:17, fontWeight:600, color:T.primary, fontFamily:FONT, letterSpacing:-0.1}}>{t}</div>
                  <div style={{fontSize:14, color:T.secondary, fontFamily:FONT, marginTop:6, lineHeight:'20px'}}>{d}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <div style={{padding:'20px 32px 0'}}>
        <Label>Token Architecture — 3 Tiers</Label>
        <div style={{display:'flex', gap:12, fontFamily:FONT}}>
          {[
            ['Tier 1','PRIMITIVE','Raw values. Never referenced by components. color.teal.700 = #0F6E5C',T.n100, T.primary],
            ['Tier 2','SEMANTIC','Intent-based. Referenced by most components. color.action.primary.default',T.teal100, T.teal900],
            ['Tier 3','COMPONENT','Scoped to a specific component. button.primary.bg',T.ochre100, T.ochre900],
          ].map(([t,h,d,bg,fg],i) => (
            <div key={i} style={{flex:1, background:bg, borderRadius:12, padding:16, color:fg}}>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.8, opacity:0.7}}>{t}</div>
              <div style={{fontSize:20, fontWeight:700, marginTop:4, letterSpacing:-0.2}}>{h}</div>
              <div style={{fontSize:13, marginTop:8, opacity:0.85, lineHeight:'18px'}}>{d}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function PrimitivesBoard() {
  const scales = [
    ['Neutral — warm gray, the backbone of the app', 'neutral', [['50',T.n50,false],['100',T.n100,false],['200',T.n200,false],['300',T.n300,false],['400',T.n400,false],['500',T.n500,true],['600',T.n600,true],['700',T.n700,true],['800',T.n800,true],['900',T.n900,true]]],
    ['Teal — brand primary (Minahasan deep teal)', 'teal', [['50',T.teal50,false],['100',T.teal100,false],['200',T.teal200,false],['300',T.teal300,false],['400',T.teal400,true],['500',T.teal500,true],['600 ★',T.teal600,true],['700',T.teal700,true],['800',T.teal800,true],['900',T.teal900,true]]],
    ['Ochre — accent (warm sunset)', 'ochre', [['50',T.ochre50,false],['100',T.ochre100,false],['200',T.ochre200,false],['300',T.ochre300,false],['400 ★',T.ochre400,false],['500',T.ochre500,false],['600',T.ochre600,true],['700',T.ochre700,true],['800',T.ochre800,true],['900',T.ochre900,true]]],
  ];
  const statusScales = [
    ['Green · Success', [['50',T.green50,false],['400',T.green400,true],['500 ★',T.green500,true],['600',T.green600,true],['700',T.green700,true]]],
    ['Amber · Warning', [['50',T.amber50,false],['400',T.amber400,false],['500 ★',T.amber500,true],['600',T.amber600,true],['700',T.amber700,true]]],
    ['Red · Danger', [['50',T.red50,false],['400',T.red400,true],['500 ★',T.red500,true],['600',T.red600,true],['700',T.red700,true]]],
    ['Blue · Info', [['50',T.blue50,false],['400',T.blue400,true],['500 ★',T.blue500,true],['600',T.blue600,true],['700',T.blue700,true]]],
  ];
  const rooms = [['1 · Teal',T.room1],['2 · Ochre',T.room2],['3 · Violet',T.room3],['4 · Red',T.room4],['5 · Blue',T.room5],['6 · Green',T.room6],['7 · Rose',T.room7],['8 · Graphite',T.room8]];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Color · Primitive Scales" subtitle="Tier 1 values. Each hue has a 10-step scale (50 → 900). These are never referenced by components directly — semantic tokens resolve to them."/>
      <div style={{padding:'24px 32px'}}>
        {scales.map(([name, key, steps]) => (
          <div key={key} style={{marginBottom:22}}>
            <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:8, fontFamily:FONT}}>{name}</div>
            <div style={{display:'flex', gap:6}}>
              {steps.map(([s,h,light]) => <Swatch key={s} step={s} hex={h} textLight={light}/>)}
            </div>
          </div>
        ))}

        <div style={{marginTop:24}}>
          <Label>Status Scales</Label>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:16}}>
            {statusScales.map(([name, steps]) => (
              <div key={name}>
                <div style={{fontSize:12, fontWeight:600, color:T.secondary, marginBottom:6, fontFamily:FONT}}>{name}</div>
                <div style={{display:'flex', gap:6}}>
                  {steps.map(([s,h,light]) => <Swatch key={s} step={s} hex={h} textLight={light}/>)}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div style={{marginTop:28}}>
          <Label>Room Accent Palette</Label>
          <div style={{fontSize:13, color:T.secondary, marginBottom:10, fontFamily:FONT, maxWidth:620, lineHeight:'20px'}}>
            Each room is assigned one of 8 accents deterministically. Inside a room's screens, this replaces brand primary as that room's identity color.
          </div>
          <div style={{display:'grid', gridTemplateColumns:'repeat(8,1fr)', gap:8}}>
            {rooms.map(([n,h]) => (
              <div key={n}>
                <div style={{height:72, background:h, borderRadius:10}}/>
                <div style={{fontSize:11, color:T.secondary, marginTop:6, fontFamily:FONT, fontWeight:500}}>{n}</div>
                <div style={{fontSize:10, color:T.tertiary, fontFamily:MONO, marginTop:1}}>{h}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function SemanticBoard() {
  const pairs = (light, dark) => ({light, dark});
  const surfaces = [
    ['surface.canvas', '#FAFAF7', '#101311'],
    ['surface.default', '#FFFFFF', '#181B19'],
    ['surface.raised', '#FFFFFF', '#1F2321'],
    ['surface.overlay', '#FFFFFF', '#262A28'],
    ['surface.muted', '#F3F2ED', 'rgba(34,38,36,0.51)'],
    ['surface.inverse', '#111613', '#FAFAF7'],
    ['scrim', 'rgba(0,0,0,0.40)', 'rgba(0,0,0,0.60)'],
  ];
  const content = [
    ['content.primary', '#111613', '#F2F2EC'],
    ['content.secondary', '#5A6160', '#B8BCB6'],
    ['content.tertiary', '#9AA09E', '#8A8E88'],
    ['content.disabled', '#B0B2AC', '#5A5E58'],
    ['content.inverse', '#FFFFFF', '#111613'],
    ['content.brand', '#0F6E5C', '#67B5A0'],
    ['content.accent', '#E8922F', '#F5BC6D'],
  ];
  const border = [
    ['border.subtle', '#EAEAE4', '#2E3230'],
    ['border.default', '#D4D4CE', '#3A3E3C'],
    ['border.strong', '#B0B2AC', '#525652'],
    ['border.focus', '#188268', '#67B5A0'],
    ['border.danger', '#C5443E', '#D15C55'],
  ];
  const action = [
    ['action.primary.default', '#0F6E5C', '#188268'],
    ['action.primary.hover', '#0A5A4B', '#3E9C82'],
    ['action.primary.pressed', '#06463B', '#67B5A0'],
    ['action.primary.disabled', '#D4D4CE', '#3A3E3C'],
    ['action.secondary.default', '#FFFFFF', '#1F2321'],
    ['action.danger.default', '#C5443E', '#D15C55'],
  ];
  const status = [
    ['status.success / surface', '#2F8F5E · #E8F5EC', '#4FA678 · #1A2E22'],
    ['status.warning / surface', '#D49A2B · #FDF4E0', '#E0A93A · #2E2414'],
    ['status.danger / surface', '#C5443E · #FBEAE9', '#D15C55 · #2E1A18'],
    ['status.info / surface', '#3E7AC5 · #E6EEF8', '#5A8FCE · #18242E'],
  ];
  const Pair = ({hex}) => {
    const parts = hex.split(' · ');
    return (
      <div style={{display:'flex', gap:4}}>
        {parts.map((p,i) => (
          <div key={i} style={{width:parts.length===1?48:24, height:20, borderRadius:4, background:p, border:`1px solid rgba(0,0,0,0.08)`}}/>
        ))}
      </div>
    );
  };
  const TokTable = ({title, data}) => (
    <div style={{marginBottom:22}}>
      <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:8, fontFamily:FONT}}>{title}</div>
      <div style={{border:`1px solid ${T.bSubtle}`, borderRadius:12, background:T.surface, overflow:'hidden'}}>
        <div style={{display:'grid', gridTemplateColumns:'1.4fr 1fr 1fr', padding:'10px 14px', background:T.muted, fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', fontFamily:FONT}}>
          <div>Token</div><div>Light</div><div>Dark</div>
        </div>
        {data.map(([t,l,d], i) => (
          <div key={t} style={{display:'grid', gridTemplateColumns:'1.4fr 1fr 1fr', padding:'10px 14px', borderTop:`1px solid ${T.bSubtle}`, alignItems:'center', fontFamily:FONT}}>
            <div style={{fontSize:13, color:T.primary, fontFamily:MONO}}>{t}</div>
            <div style={{display:'flex', alignItems:'center', gap:8, fontSize:11, color:T.secondary, fontFamily:MONO}}><Pair hex={l}/><span>{l}</span></div>
            <div style={{display:'flex', alignItems:'center', gap:8, fontSize:11, color:T.secondary, fontFamily:MONO}}><Pair hex={d}/><span>{d}</span></div>
          </div>
        ))}
      </div>
    </div>
  );
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Color · Semantic Tokens" subtitle="Tier 2 intent-based tokens. Components reference these. Theming (light ↔ dark) only changes Tier 2 mappings; Tier 1 values are immutable."/>
      <div style={{padding:'24px 32px'}}>
        <TokTable title="Surface & Background" data={surfaces}/>
        <TokTable title="Content (text & iconography)" data={content}/>
        <TokTable title="Border" data={border}/>
        <TokTable title="Action (interactive intent)" data={action}/>
        <TokTable title="Status" data={status}/>

        <div style={{marginTop:10, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Color Usage Rules</div>
          <ol style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Money amounts are always <b>content.primary</b>. Semantic colors only in budget delta / over-budget contexts.</li>
            <li>Color alone never conveys meaning — always pair with icon, label, or pattern.</li>
            <li>Brand primary is a CTA color. One primary action per screen, active nav states, and brand marks.</li>
            <li>Room accents override brand primary inside a specific room's screens.</li>
            <li>Dark mode parity is required. No screen ships until verified in both themes.</li>
          </ol>
        </div>
      </div>
    </div>
  );
}

function ContrastBoard() {
  const rows = [
    ['Body text on surface.default', 'content.primary · #FFFFFF', 19.2, '4.5:1'],
    ['Body text on surface.canvas', 'content.primary · #FAFAF7', 18.6, '4.5:1'],
    ['Secondary text on surface.default', 'content.secondary · #FFFFFF', 6.9, '4.5:1'],
    ['Brand text on surface.default', 'content.brand · #FFFFFF', 5.3, '4.5:1'],
    ['Inverse text on brand', '#FFFFFF · action.primary.default', 5.3, '4.5:1'],
    ['Danger text on danger.surface', 'status.danger.content · #FBEAE9', 5.8, '4.5:1'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Contrast & Accessibility" subtitle="WCAG 2.2 AA is a ship requirement, not an enhancement. All Tier 2 mappings are pre-verified to meet these ratios on their intended surfaces."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Minimum Ratios</Label>
        <div style={{display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:12, marginBottom:24}}>
          {[
            ['4.5:1','Body text', 'on any surface'],
            ['3:1','Large text (≥18pt)', '+ icons'],
            ['3:1','Non-text UI', 'borders, focus ring'],
            ['—','Disabled content', 'exempt from minimum'],
          ].map(([r,n,d]) => (
            <div key={n} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:16}}>
              <div style={{fontSize:28, fontWeight:600, color:T.brand, fontFamily:FONT, letterSpacing:-0.3}}>{r}</div>
              <div style={{fontSize:14, fontWeight:600, color:T.primary, marginTop:2, fontFamily:FONT}}>{n}</div>
              <div style={{fontSize:12, color:T.secondary, marginTop:2, fontFamily:FONT}}>{d}</div>
            </div>
          ))}
        </div>

        <Label>Verified Pairings</Label>
        <div style={{border:`1px solid ${T.bSubtle}`, borderRadius:12, background:T.surface, overflow:'hidden'}}>
          {rows.map(([pair, token, ratio, min], i) => (
            <div key={i} style={{display:'grid', gridTemplateColumns:'1.6fr 1.4fr 0.6fr 0.6fr', padding:'14px 16px', borderTop:i===0?'none':`1px solid ${T.bSubtle}`, alignItems:'center', fontFamily:FONT}}>
              <div style={{fontSize:13, color:T.primary, fontWeight:500}}>{pair}</div>
              <div style={{fontSize:12, color:T.secondary, fontFamily:MONO}}>{token}</div>
              <div style={{fontSize:13, fontWeight:600, color:ratio>=4.5?'#2F8F5E':'#D49A2B', fontVariantNumeric:'tabular-nums'}}>{ratio}:1</div>
              <div style={{fontSize:12, color:T.tertiary, fontVariantNumeric:'tabular-nums'}}>min {min}</div>
            </div>
          ))}
        </div>

        <div style={{marginTop:20, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Additional Baselines</div>
          <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Minimum tappable target: <b>44×44pt</b> anywhere. Spacing between adjacent targets ≥ 8pt.</li>
            <li>Dynamic type: OS scaling up to 150% supported without clipping or layout breakage.</li>
            <li>Reduce motion: substitute instant transitions (0ms) or cross-fades only.</li>
            <li>Focus indicator: <b>border.focus</b>, 2px outline, 2px offset.</li>
            <li>Color-blindness: pair every color signal with icon, label, pattern, or text.</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

function TypeBoard() {
  const scale = [
    ['display.l', 48, 52, 600, -0.5, 'Paywall hero, first-run moments'],
    ['display.m', 40, 44, 600, -0.4, 'Dashboard total amount'],
    ['display.s', 32, 36, 600, -0.3, 'Secondary hero, onboarding'],
    ['title.l', 24, 30, 600, -0.2, 'Screen titles'],
    ['title.m', 20, 26, 600, -0.15, 'Section titles'],
    ['title.s', 17, 22, 600, -0.1, 'Card titles, list group headers'],
    ['body.l', 16, 24, 400, 0, 'Default body, button label'],
    ['body.m', 14, 20, 400, 0, 'Secondary body, metadata'],
    ['body.s', 12, 16, 500, 0.1, 'Captions, chip label, tag'],
    ['label.l', 14, 18, 600, 0.2, 'Form field labels'],
    ['label.m', 12, 16, 600, 0.3, 'Chip filled, overline'],
    ['label.s', 11, 14, 600, 0.4, 'Badge, micro-tag'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Typography" subtitle="Primary typeface: Inter (variable 400–700). Bundled on both platforms. Mono: JetBrains Mono for developer-facing surfaces only. Max 3 sizes per screen."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Type Scale</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
          {scale.map(([t,s,lh,w,tk,use], i) => (
            <div key={t} style={{display:'grid', gridTemplateColumns:'180px 1fr 200px', alignItems:'baseline', padding:'16px 18px', borderTop:i===0?'none':`1px solid ${T.bSubtle}`, gap:12}}>
              <div>
                <div style={{fontSize:12, fontWeight:600, color:T.primary, fontFamily:MONO}}>{t}</div>
                <div style={{fontSize:10, color:T.tertiary, fontFamily:MONO, marginTop:3}}>{s}/{lh} · {w} · {tk>=0?'+':''}{tk}</div>
              </div>
              <div style={{fontSize:s, lineHeight:lh+'px', fontWeight:w, letterSpacing:tk, fontFamily:FONT, color:T.primary, overflow:'hidden'}}>Split bills, not friendships</div>
              <div style={{fontSize:12, color:T.secondary, fontFamily:FONT}}>{use}</div>
            </div>
          ))}
        </div>

        <div style={{marginTop:28}}>
          <Label>Numeric Typography — Money is the Hero</Label>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:24, fontFamily:FONT}}>
            <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:24}}>
              <div>
                <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:8}}>amount.hero · 40/600 · tnum · cv11</div>
                <div style={{fontSize:40, fontWeight:600, fontVariantNumeric:'tabular-nums', color:T.primary, letterSpacing:-0.4}}>Rp 4.235.000</div>
                <div style={{fontSize:40, fontWeight:600, fontVariantNumeric:'tabular-nums', color:T.primary, letterSpacing:-0.4}}>$ 1,234.56</div>
              </div>
              <div>
                <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:8}}>amount.large · 24/600 · tnum</div>
                <div style={{fontSize:24, fontWeight:600, fontVariantNumeric:'tabular-nums', color:T.primary}}>Rp 385.000</div>
                <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginTop:20, marginBottom:8}}>amount.default · 16/600 · tnum</div>
                <div style={{fontSize:16, fontWeight:600, fontVariantNumeric:'tabular-nums', color:T.primary}}>Rp 85.000</div>
                <div style={{fontSize:16, fontWeight:600, fontVariantNumeric:'tabular-nums', color:'#C5443E'}}>−Rp 12.000</div>
                <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginTop:20, marginBottom:8}}>amount.small · 14/500 · tnum</div>
                <div style={{fontSize:14, fontWeight:500, fontVariantNumeric:'tabular-nums', color:T.secondary}}>Yesterday · 14.30 WIB</div>
              </div>
            </div>
            <div style={{marginTop:20, paddingTop:16, borderTop:`1px solid ${T.bSubtle}`, fontSize:13, color:T.secondary, lineHeight:'20px'}}>
              <b>Rules.</b> All amounts use <code style={{fontFamily:MONO, fontSize:12, color:T.primary}}>tnum</code> (tabular numerals) so columns align. Currency symbols sit tight-adjacent to the number. Negative amounts use a minus sign, not parentheses. IDR default 0 decimals; USD default 2.
            </div>
          </div>
        </div>

        <div style={{marginTop:22, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Typographic Rules</div>
          <ol style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Maximum 3 type sizes per screen. More than that signals a hierarchy problem.</li>
            <li>Line length caps at 60 characters for body prose.</li>
            <li>Never use weight alone for emphasis. Pair with color or size.</li>
            <li>Truncate with ellipsis; never wrap beyond 2 lines in list rows. Amounts never truncate — shrink what's beside them first.</li>
            <li>Respect OS text scaling up to 150%.</li>
          </ol>
        </div>
      </div>
    </div>
  );
}

function SpaceBoard() {
  const space = [[0,0],[1,2],[2,4],[3,8],[4,12],[5,16],[6,20],[7,24],[8,32],[9,40],[10,48],[11,64]];
  const sizes = [
    ['icon.xs',14,'Inline with body.s'],
    ['icon.s',16,'Inline with body.m'],
    ['icon.m',20,'List row leading'],
    ['icon.l',24,'Nav, app bar, actions'],
    ['icon.xl',32,'Illustrated accents'],
    ['avatar.xs',20,'Dense stacks'],
    ['avatar.s',28,'Presence row'],
    ['avatar.m',40,'List rows'],
    ['avatar.l',56,'Profile header'],
    ['avatar.xl',96,'Settings profile'],
    ['control.s',36,'Dense inputs'],
    ['control.m',44,'Default control (hit-target)'],
    ['control.l',52,'Primary button'],
    ['hit.min',44,'Minimum tappable · anywhere'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Space, Size & Grid" subtitle="Base unit: 4pt. Every margin, padding, and gap is a multiple of the base. Mobile-first single column; tablet centers content at 560pt."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Spacing Scale · 4pt base</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20}}>
          {space.map(([k,v]) => (
            <div key={k} style={{display:'grid', gridTemplateColumns:'90px 60px 1fr', alignItems:'center', padding:'6px 0', fontFamily:FONT}}>
              <div style={{fontSize:12, fontWeight:600, fontFamily:MONO, color:T.primary}}>space.{k}</div>
              <div style={{fontSize:12, color:T.secondary, fontFamily:MONO}}>{v}pt</div>
              <div style={{height:16, width:v, background:T.brand, borderRadius:4}}/>
            </div>
          ))}
        </div>

        <div style={{marginTop:24}}>
          <Label>Sizing Scale · Icons, avatars, controls</Label>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            {sizes.map(([t,v,u], i) => (
              <div key={t} style={{display:'grid', gridTemplateColumns:'140px 80px 100px 1fr', padding:'12px 18px', borderTop:i===0?'none':`1px solid ${T.bSubtle}`, alignItems:'center', fontFamily:FONT}}>
                <div style={{fontSize:12, fontWeight:600, fontFamily:MONO, color:T.primary}}>size.{t}</div>
                <div style={{fontSize:12, color:T.secondary, fontFamily:MONO}}>{v}pt</div>
                <div style={{display:'flex', alignItems:'center'}}>
                  {t.startsWith('avatar') ? <Avatar size={Math.min(v,56)} initials="M" color={T.brand}/> :
                   t.startsWith('icon') ? <div style={{width:Math.min(v,32), height:Math.min(v,32), borderRadius:6, background:T.muted, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.receipt} size={Math.min(v,32)-4} stroke={T.brand}/></div> :
                   <div style={{height:v, padding:'0 16px', borderRadius:12, background:T.brand, color:'#fff', fontSize:13, fontWeight:600, display:'inline-flex', alignItems:'center'}}>Button</div>}
                </div>
                <div style={{fontSize:12, color:T.secondary}}>{u}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{marginTop:24}}>
          <Label>Layout Grid</Label>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <div style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr 1fr', padding:'10px 16px', background:T.muted, fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', fontFamily:FONT}}>
              <div>Breakpoint</div><div>Width</div><div>Columns</div><div>Horizontal padding</div>
            </div>
            {[['Compact phone','320–359','1','space.4 · 12'],['Default phone','360–479','1','space.5 · 16'],['Large phone','480–599','1','space.5 · 16'],['Small tablet','600–839','1 · max 560','space.7 · 24'],['Tablet+','840+','centered 560','auto']].map((r,i) => (
              <div key={i} style={{display:'grid', gridTemplateColumns:'1fr 1fr 1fr 1fr', padding:'10px 16px', borderTop:`1px solid ${T.bSubtle}`, fontSize:13, color:T.primary, fontFamily:FONT}}>
                {r.map((x,j) => <div key={j} style={{fontFamily: j===0?FONT:MONO, fontSize:j===0?13:12, color:j===0?T.primary:T.secondary}}>{x}</div>)}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function RadiusElevationBoard() {
  const radii = [['none',0],['xs',4],['s',8],['m',12],['l',16],['xl',24],['2xl',32],['full',999]];
  const elev = [
    ['elevation.0','Border only','0 0 0 + 1px border.subtle','Default cards, list rows'],
    ['elevation.1','0 1px 2px rgba(17,22,19,0.04)','0 1px 2px rgba(17,22,19,0.04)','Raised cards, tab bar'],
    ['elevation.2','0 4px 12px rgba(17,22,19,0.08)','0 4px 12px rgba(17,22,19,0.08)','FAB, toast'],
    ['elevation.3','0 12px 32px rgba(17,22,19,0.12)','0 12px 32px rgba(17,22,19,0.12)','Bottom sheet, modal'],
    ['elevation.4','0 24px 64px rgba(17,22,19,0.16)','0 24px 64px rgba(17,22,19,0.16)','Full-screen overlay'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Radius & Elevation" subtitle="Soft rounded shapes — generous but not playful. Low, soft shadows — not Material's heavy spread. Most surface separation is border-based."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Radius Tokens</Label>
        <div style={{display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:14}}>
          {radii.map(([t,v]) => (
            <div key={t} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:16, fontFamily:FONT}}>
              <div style={{height:72, background:T.teal100, borderRadius:Math.min(v,56), marginBottom:10, border:`1px solid ${T.bSubtle}`}}/>
              <div style={{fontSize:12, fontWeight:600, color:T.primary, fontFamily:MONO}}>radius.{t}</div>
              <div style={{fontSize:11, color:T.tertiary, fontFamily:MONO, marginTop:2}}>{v===999?'999 · full':`${v}pt`}</div>
            </div>
          ))}
        </div>
        <div style={{marginTop:8, padding:12, background:T.muted, borderRadius:8, fontSize:12, color:T.secondary, fontFamily:FONT, lineHeight:'18px'}}>
          <b>Corner-smoothing:</b> where Flutter supports <code style={{fontFamily:MONO}}>ContinuousRectangleBorder</code>, prefer continuous (squircle) corners over standard round-rect for surfaces with 16pt+ radius.
        </div>

        <div style={{marginTop:28}}>
          <Label>Elevation Tokens</Label>
          <div style={{display:'grid', gridTemplateColumns:'repeat(5,1fr)', gap:14}}>
            {elev.map(([t,l,cs,u]) => (
              <div key={t} style={{display:'flex', flexDirection:'column'}}>
                <div style={{padding:24, background:T.canvas, borderRadius:12}}>
                  <div style={{height:80, borderRadius:12, background:T.surface,
                    border: t==='elevation.0'?`1px solid ${T.bSubtle}`:'none',
                    boxShadow: t==='elevation.0'?'none':cs}}/>
                </div>
                <div style={{fontSize:12, fontWeight:600, color:T.primary, fontFamily:MONO, marginTop:4}}>{t}</div>
                <div style={{fontSize:11, color:T.secondary, fontFamily:FONT, marginTop:2}}>{u}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function MotionBoard() {
  const durations = [
    ['motion.instant',80,'easeOut','Press feedback, hover'],
    ['motion.short',180,'easeOut','Chip toggle, small state'],
    ['motion.base',240,'easeInOut','Default transition'],
    ['motion.emphasized',320,'cubic(0.2, 0, 0, 1)','Sheet rise, page transition'],
    ['motion.long',480,'easeInOut','Celebratory (budget save, first scan)'],
  ];
  const patterns = [
    ['Page push','Slide-from-right + 40ms fade','motion.emphasized'],
    ['Sheet rise','Translate-Y from +100% + scrim fade','motion.emphasized'],
    ['Modal present','Scale from 0.92 + fade','motion.emphasized'],
    ['List insert','Slide-down + fade','motion.base'],
    ['List remove','Fade + collapse height','motion.short'],
    ['Number tween','TweenAnimationBuilder','motion.base · decelerate'],
    ['Budget bar fill','Animate width, optional overshoot','motion.emphasized'],
    ['Skeleton shimmer','1400ms linear loop, gradient at 30% width','linear loop'],
    ['Press feedback','Scale 0.97 + opacity 0.92','motion.instant'],
    ['Success moment','Spring scale 0.8 → 1.05 → 1.0','easing.spring.soft'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Motion System" subtitle="Motion in LOIT is confident and quiet. Nothing bounces gratuitously. Every animation serves orientation, feedback, or continuity — never decoration."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Duration Tokens</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden', marginBottom:24}}>
          {durations.map(([t,ms,c,u], i) => (
            <div key={t} style={{display:'grid', gridTemplateColumns:'180px 80px 200px 1fr', padding:'14px 18px', borderTop:i===0?'none':`1px solid ${T.bSubtle}`, alignItems:'center', fontFamily:FONT}}>
              <div style={{fontSize:13, fontWeight:600, color:T.primary, fontFamily:MONO}}>{t}</div>
              <div style={{fontSize:13, color:T.primary, fontFamily:MONO, fontVariantNumeric:'tabular-nums'}}>{ms}ms</div>
              <div style={{fontSize:12, color:T.secondary, fontFamily:MONO}}>{c}</div>
              <div style={{fontSize:13, color:T.secondary}}>{u}</div>
            </div>
          ))}
        </div>

        <Label>Motion Patterns</Label>
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:14}}>
          {patterns.map(([n,d,t]) => (
            <div key={n} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:14, fontFamily:FONT}}>
              <div style={{fontSize:13, fontWeight:600, color:T.primary}}>{n}</div>
              <div style={{fontSize:12, color:T.secondary, marginTop:4}}>{d}</div>
              <div style={{fontSize:11, color:T.brand, fontFamily:MONO, marginTop:6}}>{t}</div>
            </div>
          ))}
        </div>

        <div style={{marginTop:22, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Motion Rules</div>
          <ol style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Every motion has a purpose: orientation, continuity, feedback, or celebration. Nothing is decorative.</li>
            <li>Respect <code style={{fontFamily:MONO}}>reduce-motion</code>. Non-essential animation becomes instant transitions (0ms) or cross-fades only.</li>
            <li>No motion for content the user hasn't asked for. Auto-playing animations are forbidden.</li>
            <li>Optimistic UI beats spinners. Animate the result; reconcile on server response.</li>
            <li>Consistent direction: "forward" always slides left-to-right on pop; sheets always rise from the bottom.</li>
          </ol>
        </div>
      </div>
    </div>
  );
}

function IconographyBoard() {
  const cats = [
    ['Dining','utensils','#F2A85C'],
    ['Groceries','basket','#2F8F5E'],
    ['Transport','car','#3E7AC5'],
    ['Shopping','bag','#B15FC0'],
    ['Entertainment','ticket','#E06B8A'],
    ['Utilities','plug','#5A6160'],
    ['Health','heart','#C5443E'],
    ['Travel','plane','#188268'],
    ['Other','more','#9AA09E'],
  ];
  const sizes = [14,16,20,24,32];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Iconography" subtitle="Primary: Lucide (stroke-based, 1.5px, consistent geometry). Never mix sets. Icons are monochrome and inherit content.* tokens — status icons use status tokens; the rest inherit text color."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Icon Sizes</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:20, display:'flex', gap:32, alignItems:'center', marginBottom:24}}>
          {sizes.map(s => (
            <div key={s} style={{textAlign:'center'}}>
              <div style={{height:40, display:'flex', alignItems:'center', justifyContent:'center', color:T.primary}}>
                <Ico d={icons.receipt} size={s}/>
              </div>
              <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:4}}>{s}pt</div>
            </div>
          ))}
        </div>

        <Label>Category Taxonomy · Icon + Tint</Label>
        <div style={{fontSize:13, color:T.secondary, marginBottom:12, maxWidth:640, lineHeight:'20px', fontFamily:FONT}}>
          Tints are rendered at <b>12% opacity on the icon background</b> and <b>full saturation on the icon glyph</b>. This keeps list rows visually ordered without being loud.
        </div>
        <div style={{display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12}}>
          {cats.map(([name, icon, tint]) => (
            <div key={name} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:16, display:'flex', gap:14, alignItems:'center', fontFamily:FONT}}>
              <div style={{width:40, height:40, borderRadius:'50%', background:tint+'1F',
                display:'inline-flex', alignItems:'center', justifyContent:'center', color:tint, flexShrink:0}}>
                <Ico d={icons[icon]} size={20}/>
              </div>
              <div style={{flex:1, minWidth:0}}>
                <div style={{fontSize:14, fontWeight:600, color:T.primary}}>{name}</div>
                <div style={{fontSize:11, color:T.secondary, fontFamily:MONO, marginTop:2}}>{icon} · {tint}</div>
              </div>
            </div>
          ))}
        </div>

        <div style={{marginTop:22, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
          <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Rules</div>
          <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
            <li>Never mix icon sets. A Lucide arrow and a Material arrow on the same screen is a bug.</li>
            <li>Icons are monochrome and inherit content.* tokens.</li>
            <li>Do not tint icons decoratively. Status icons use status tokens; brand icons use brand token.</li>
            <li>Icon buttons require tooltip and semanticLabel. Never icon-only without a label.</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {PrinciplesBoard, PrimitivesBoard, SemanticBoard, ContrastBoard, TypeBoard, SpaceBoard, RadiusElevationBoard, MotionBoard, IconographyBoard});
