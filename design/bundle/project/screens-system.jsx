// Settings, Profile, Paywall, Pro success, Notifications, Errors

function SettingsHome() {
  return (
    <PhoneS label="01 · Settings · home" caption="Edge-to-edge grouped rows · profile header band">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Settings"/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD, fontFamily:FONT}}>
          {/* Profile band — full bleed, no card */}
          <div style={{padding:'14px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, display:'flex', alignItems:'center', gap:12}}>
            <Avatar size={48} initials="M" color="#C5443E"/>
            <div style={{flex:1}}>
              <div style={{fontSize:16, fontWeight:600, color:T.primary}}>Maria Putri</div>
              <div style={{fontSize:12, color:T.secondary}}>maria@example.com</div>
              <span style={{padding:'2px 6px', background:T.teal50, color:T.brand, fontSize:10, fontWeight:600, borderRadius:4, letterSpacing:0.4, textTransform:'uppercase', marginTop:4, display:'inline-block'}}>Pro · Yearly</span>
            </div>
            <Ico d={icons.chevR} size={16} stroke={T.tertiary}/>
          </div>

          {[
            ['General', [['Language','English (US)'],['Currency','IDR · Rp'],['Region','Indonesia']]],
            ['Money', [['Default account','Personal'],['Budgets','5 active'],['Recurring','3 set up']]],
            ['Privacy & data', [['Biometric lock','On'],['Export data','CSV / PDF'],['Delete account',null]]],
            ['About', [['Help & support',null],['Terms & privacy',null],['Version','2.4.1 (build 1832)']]],
          ].map(([group, rows]) => (
            <React.Fragment key={group}>
              <GroupLabel>{group}</GroupLabel>
              {rows.map(([k,v], i) => (
                <div key={k} style={{padding:'14px 16px', display:'flex', alignItems:'center', borderBottom:`1px solid ${T.bSubtle}`, background:T.surface}}>
                  <div style={{flex:1, fontSize:14, color: k==='Delete account'?'#9D332E':T.primary, fontWeight: k==='Delete account'?500:400}}>{k}</div>
                  {v && <div style={{fontSize:13, color:T.secondary, marginRight:8, fontVariantNumeric:'tabular-nums'}}>{v}</div>}
                  {k!=='Delete account' && <Ico d={icons.chevR} size={14} stroke={T.tertiary}/>}
                </div>
              ))}
            </React.Fragment>
          ))}
        </div>
        <TabBar active="more"/>
      </div>
    </PhoneS>
  );
}

function ProfileEdit() {
  return (
    <PhoneS label="02 · Profile · edit" caption="Avatar tap to change · sticky save">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Profile" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:16, fontFamily:FONT}}>
          <div style={{textAlign:'center', padding:'10px 0 20px'}}>
            <div style={{position:'relative', display:'inline-block'}}>
              <Avatar size={88} initials="M" color="#C5443E"/>
              <div style={{position:'absolute', bottom:-4, right:-4, width:32, height:32, borderRadius:'50%', background:T.brand, border:`3px solid ${T.canvas}`, display:'inline-flex', alignItems:'center', justifyContent:'center', color:'#fff'}}><Ico d={icons.camera} size={16} stroke="#fff"/></div>
            </div>
          </div>
          <LoitInput label="Name" value="Maria Putri"/>
          <div style={{height:10}}/>
          <LoitInput label="Email" value="maria@example.com"/>
          <div style={{height:10}}/>
          <LoitInput label="Phone" value="+62 812 3456 7890"/>
          <div style={{height:14}}/>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', marginBottom:8}}>Notifications</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12}}>
            {[['Budget alerts',true],['Room activity',true],['Weekly digest',false],['Marketing',false]].map(([k,v], i, a) => (
              <div key={k} style={{padding:'12px 14px', display:'flex', alignItems:'center', borderBottom:i===a.length-1?'none':`1px solid ${T.bSubtle}`}}>
                <div style={{flex:1, fontSize:14, color:T.primary}}>{k}</div>
                <Toggle on={v}/>
              </div>
            ))}
          </div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Save changes"/>
        </div>
      </div>
    </PhoneS>
  );
}

function Paywall() {
  return (
    <PhoneS label="03 · Paywall · contextual" caption="Triggered at value moment · plans · trust copy">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column', overflow:'hidden'}}>
        <div style={{padding:'10px 16px 0', display:'flex', justifyContent:'flex-end'}}>
          <button style={{background:'transparent', border:'none', fontSize:13, color:T.secondary, fontWeight:600, fontFamily:FONT}}>Not now</button>
        </div>
        <div style={{padding:'18px 20px 12px', fontFamily:FONT}}>
          <div style={{width:48, height:48, borderRadius:12, background:`linear-gradient(135deg, ${T.brand}, ${T.accent})`, display:'inline-flex', alignItems:'center', justifyContent:'center', color:'#fff', marginBottom:14}}><Ico d={icons.receipt} size={24} stroke="#fff"/></div>
          <div style={{fontSize:24, fontWeight:600, color:T.primary, letterSpacing:-0.2, lineHeight:'30px'}}>Unlimited budgets.<br/>Unlimited currencies.<br/>Pro.</div>
        </div>
        <div style={{padding:'0 16px', flex:1, overflowY:'auto', fontFamily:FONT}}>
          {[
            ['Free','Rp 0','/mo','3 budgets · 8 scans · 3 months reports', false],
            ['Pro · Yearly','Rp 712.000','/yr','Save 2 months · Unlimited everything · Export', true],
            ['Pro · Monthly','Rp 85.529','/mo','Cancel anytime', false],
          ].map(([name, price, per, feat, rec]) => (
            <div key={name} style={{background:T.surface, border:rec?`2px solid ${T.brand}`:`1px solid ${T.bSubtle}`, borderRadius:12, padding:14, marginBottom:10, position:'relative'}}>
              {rec && <div style={{position:'absolute', top:-10, left:14, padding:'2px 8px', background:T.brand, color:'#fff', fontSize:10, fontWeight:700, letterSpacing:0.5, textTransform:'uppercase', borderRadius:4}}>Best value</div>}
              <div style={{display:'flex', justifyContent:'space-between'}}>
                <div style={{fontSize:15, fontWeight:600, color:T.primary}}>{name}</div>
                <div style={{textAlign:'right'}}>
                  <span style={{fontSize:18, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>{price}</span>
                  <span style={{fontSize:12, color:T.secondary}}>{per}</span>
                </div>
              </div>
              <div style={{fontSize:12, color:T.secondary, marginTop:6, lineHeight:'17px'}}>{feat}</div>
            </div>
          ))}
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Start Pro · Rp 712.000/yr"/>
          <div style={{fontSize:11, color:T.tertiary, textAlign:'center', marginTop:8, fontFamily:FONT}}>Billed via Midtrans · Cancel anytime · Terms & Privacy</div>
        </div>
      </div>
    </PhoneS>
  );
}

function ProSuccess() {
  return (
    <PhoneS label="04 · Pro · welcome" caption="Calm celebration · what's unlocked · clear next step">
      <div style={{height:'100%', background:`linear-gradient(180deg, ${T.teal50}, ${T.canvas})`, display:'flex', flexDirection:'column', padding:24, fontFamily:FONT}}>
        <div style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', textAlign:'center'}}>
          <div style={{width:96, height:96, borderRadius:24, background:`linear-gradient(135deg, ${T.brand}, ${T.accent})`, display:'inline-flex', alignItems:'center', justifyContent:'center', boxShadow:'0 12px 32px rgba(15,110,92,0.3)', marginBottom:20}}>
            <Ico d={icons.check} size={48} stroke="#fff" sw={3}/>
          </div>
          <div style={{fontSize:13, fontWeight:600, color:T.brand, letterSpacing:1.2, textTransform:'uppercase'}}>Welcome to Pro</div>
          <div style={{fontSize:28, fontWeight:600, color:T.primary, letterSpacing:-0.3, marginTop:8, lineHeight:'34px', maxWidth:260}}>You're all set, Maria.</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:10, maxWidth:260, lineHeight:'20px'}}>Everything's unlocked. Your subscription renews 12 Nov 2027.</div>
          <div style={{marginTop:24, width:'100%', maxWidth:280, background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:14, padding:16, textAlign:'left'}}>
            <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', marginBottom:10}}>Now unlocked</div>
            {['Unlimited budgets','Unlimited receipt scans','CSV & PDF export','Multi-currency','Advanced insights'].map(f => (
              <div key={f} style={{display:'flex', gap:10, alignItems:'center', padding:'5px 0', fontSize:13, color:T.primary}}>
                <Ico d={icons.check} size={16} stroke={T.brand} sw={2.5}/>{f}
              </div>
            ))}
          </div>
        </div>
        <LoitButton size="l" fullWidth label="Start using Pro"/>
      </div>
    </PhoneS>
  );
}

function Notifications() {
  return (
    <PhoneS label="05 · Notifications · feed" caption="Read / unread · grouped · swipe to dismiss">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Notifications" trailing={<span style={{fontSize:13, color:T.brand, fontWeight:600, fontFamily:FONT}}>Mark all read</span>}/>
        <div style={{flex:1, overflowY:'auto', padding:'8px 12px 88px', fontFamily:FONT}}>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', margin:'4px 4px 6px'}}>New · 3</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            {[
              ['Budget alert','#C5443E','alert','Transport budget exceeded by Rp 250.000','2 min ago', true],
              ['New expense in Bali Trip','#7A4FBF','users','Alex added Bebek Bengil · Rp 285.000','1 h ago', true],
              ['Weekly summary','#3E7AC5','info',"You're 12% under budget this week. Keep going.",'1 d ago', true],
            ].map(([t,col,ic,d,when,unread], i, a) => (
              <div key={i} style={{padding:'14px 16px', display:'flex', gap:12, borderBottom:i===a.length-1?'none':`1px solid ${T.bSubtle}`, position:'relative'}}>
                {unread && <div style={{position:'absolute', left:6, top:'50%', transform:'translateY(-50%)', width:6, height:6, borderRadius:'50%', background:T.brand}}/>}
                <div style={{width:36, height:36, borderRadius:'50%', background:col+'1F', color:col, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0, marginLeft:6}}><Ico d={icons[ic]} size={18}/></div>
                <div style={{flex:1, minWidth:0}}>
                  <div style={{fontSize:14, fontWeight:600, color:T.primary}}>{t}</div>
                  <div style={{fontSize:13, color:T.secondary, marginTop:2, lineHeight:'17px'}}>{d}</div>
                  <div style={{fontSize:11, color:T.tertiary, marginTop:4, fontFamily:MONO}}>{when}</div>
                </div>
              </div>
            ))}
          </div>
          <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', margin:'18px 4px 6px'}}>Earlier</div>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            {[
              ['Reza joined Movie Night','#2F8F5E','users','3 d ago'],
              ['Receipt scanned','#0F6E5C','receipt','Alfamart · Rp 42.500 · 4 d ago'],
            ].map(([t,col,ic,d], i, a) => (
              <div key={i} style={{padding:'14px 16px', display:'flex', gap:12, borderBottom:i===a.length-1?'none':`1px solid ${T.bSubtle}`}}>
                <div style={{width:36, height:36, borderRadius:'50%', background:col+'1F', color:col, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0}}><Ico d={icons[ic]} size={18}/></div>
                <div style={{flex:1, minWidth:0}}>
                  <div style={{fontSize:14, color:T.primary}}>{t}</div>
                  <div style={{fontSize:11, color:T.tertiary, marginTop:3, fontFamily:MONO}}>{d}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </PhoneS>
  );
}

function ErrorBlocking() {
  return (
    <PhoneS label="06 · Error · server unreachable" caption="Recoverable · friendly · always offers a path">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title=""/>
        <div style={{flex:1, padding:'40px 24px', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', textAlign:'center', fontFamily:FONT}}>
          <div style={{width:120, height:120, borderRadius:24, background:'#FBEAE9', display:'inline-flex', alignItems:'center', justifyContent:'center', color:'#9D332E', marginBottom:22}}>
            <Ico d={icons.alert} size={48}/>
          </div>
          <div style={{fontSize:13, fontWeight:600, color:'#9D332E', letterSpacing:1.2, textTransform:'uppercase'}}>Couldn't load</div>
          <div style={{fontSize:22, fontWeight:600, color:T.primary, letterSpacing:-0.2, marginTop:8, maxWidth:260, lineHeight:'27px'}}>Something is delayed on our end</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:10, maxWidth:280, lineHeight:'20px'}}>This isn't your connection. We're already on it. Personal tracking still works.</div>
          <div style={{display:'flex', gap:10, marginTop:22}}>
            <LoitButton size="m" variant="secondary" label="Personal"/>
            <LoitButton size="m" label="Retry"/>
          </div>
          <div style={{marginTop:18, fontSize:11, color:T.tertiary, fontFamily:MONO}}>error · 503 · req_8af2c1</div>
        </div>
      </div>
    </PhoneS>
  );
}

function SettingsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="I · Settings & Profile" title="Where the system breathes" subtitle="Settings home (grouped) · profile edit · notifications feed."/>
      <ScreensGrid>
        <SettingsHome/>
        <ProfileEdit/>
        <Notifications/>
      </ScreensGrid>
    </div>
  );
}

function PaywallArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="J · Pro / Paywall" title="Value-first, never dark-pattern" subtitle="Contextual paywall · Pro welcome (calm celebration). Trust copy is part of the system."/>
      <ScreensGrid>
        <Paywall/>
        <ProSuccess/>
        <ErrorBlocking/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {SettingsArtboard, PaywallArtboard});
