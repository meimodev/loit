// Patterns & screen examples: forms, list+filter, detail, confirm, paywall, scan, offline, dashboard

function ScreenDashboard({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <Phone theme={theme} label="Personal Dashboard · Home">
      <div style={{padding:'12px 16px 80px', overflowY:'auto', height:'100%', background:c.canvas}}>
        <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10}}>
          <div style={{fontSize:22, fontWeight:600, color:c.primary, letterSpacing:-0.2}}>Hi, Maria</div>
          <div style={{padding:'6px 12px', background:c.surface, border:`1px solid ${c.bSubtle}`, borderRadius:999, fontSize:12, fontWeight:600, color:c.primary}}>November 2026 ▾</div>
        </div>

        <div style={{background:c.surface, border:`1px solid ${c.bSubtle}`, borderRadius:16, padding:16, marginTop:8}}>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:c.secondary}}>Spent this month</div>
          <div style={{fontSize:40, fontWeight:600, color:c.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4, marginTop:6}}>Rp 4.235.000</div>
          <div style={{marginTop:8, display:'inline-flex', alignItems:'center', gap:6, padding:'4px 8px', background:theme==='dark'?'#1A2E22':'#E8F5EC', color:theme==='dark'?'#4FA678':'#227549', borderRadius:999, fontSize:12, fontWeight:600}}>
            <Ico d={icons.arrowDown} size={12}/> 12% vs October
          </div>
        </div>

        <div style={{marginTop:14}}>
          <div style={{fontSize:13, fontWeight:600, color:c.secondary, marginBottom:8, letterSpacing:0.3, textTransform:'uppercase'}}>Budgets</div>
          {[['Dining','utensils','#F2A85C',82],['Groceries','basket','#2F8F5E',48],['Transport','car','#3E7AC5',125]].map(([n,ic,t,p]) => (
            <div key={n} style={{background:c.surface, border:`1px solid ${c.bSubtle}`, borderRadius:12, padding:12, marginBottom:8, display:'flex', alignItems:'center', gap:12}}>
              <div style={{width:36, height:36, borderRadius:'50%', background:t+'1F', color:t, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons[ic]} size={18}/></div>
              <div style={{flex:1}}>
                <div style={{display:'flex', justifyContent:'space-between', fontSize:13, fontWeight:500, color:c.primary}}>
                  <span>{n}</span><span style={{fontVariantNumeric:'tabular-nums', fontWeight:600}}>{p}%</span>
                </div>
                <div style={{marginTop:6}}><BudgetBar pct={p} theme={theme}/></div>
              </div>
            </div>
          ))}
        </div>

        <div style={{marginTop:14}}>
          <div style={{display:'flex', justifyContent:'space-between', marginBottom:8}}>
            <div style={{fontSize:13, fontWeight:600, color:c.secondary, letterSpacing:0.3, textTransform:'uppercase'}}>Recent</div>
            <div style={{fontSize:13, color:c.brand, fontWeight:600}}>See all →</div>
          </div>
          <div style={{background:c.surface, border:`1px solid ${c.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            <TxRow merchant="Warung Sari Rasa" cat="Dining" date="Today" amount="Rp 85.000" theme={theme}/>
            <TxRow merchant="Shell Kemang" cat="Transport" date="Today" amount="Rp 150.000" receipt theme={theme}/>
            <TxRow merchant="Alfamart" cat="Groceries" date="Yesterday" amount="Rp 42.500" aiScanned theme={theme} last/>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function ScreenScanReview({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <Phone theme={theme} label="Scan · Confirmation">
      <div style={{height:'100%', background:c.canvas, display:'flex', flexDirection:'column'}}>
        <div style={{height:52, padding:'0 8px', display:'flex', alignItems:'center', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`}}>
          <button style={{width:44, height:44, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center', color:c.primary}}><Ico d={icons.x} size={22}/></button>
          <div style={{fontSize:17, fontWeight:600, color:c.primary, marginLeft:4, flex:1}}>Confirm receipt</div>
          <span style={{padding:'4px 8px', background:c.teal50||'#E6F4F0', color:c.brand, fontSize:10, fontWeight:600, borderRadius:4, letterSpacing:0.4, textTransform:'uppercase'}}>AI</span>
        </div>
        <div style={{padding:16, overflowY:'auto', flex:1}}>
          <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, padding:14, marginBottom:12}}>
            <div style={{fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', color:c.secondary, marginBottom:4}}>Merchant</div>
            <div style={{fontSize:17, fontWeight:600, color:c.primary}}>Warung Sari Rasa</div>
          </div>
          <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, padding:14, marginBottom:12}}>
            <div style={{fontSize:11, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', color:c.secondary, marginBottom:4}}>Total</div>
            <div style={{fontSize:32, fontWeight:600, color:c.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.3}}>Rp 85.000</div>
          </div>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10, marginBottom:12}}>
            <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, padding:12}}>
              <div style={{fontSize:11, color:c.secondary, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase'}}>Date</div>
              <div style={{fontSize:14, fontWeight:500, color:c.primary, marginTop:3}}>Today · 14.30</div>
            </div>
            <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, padding:12}}>
              <div style={{fontSize:11, color:c.secondary, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase'}}>Category</div>
              <div style={{fontSize:14, fontWeight:500, color:c.primary, marginTop:3, display:'flex', alignItems:'center', gap:6}}><Ico d={icons.utensils} size={14} stroke="#F2A85C"/> Dining</div>
            </div>
          </div>
          <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, padding:14}}>
            <div style={{fontSize:11, color:c.secondary, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase', marginBottom:8}}>Save to</div>
            <div style={{display:'flex', flexDirection:'column', gap:8}}>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Radio checked theme={theme}/><span style={{fontSize:14, color:c.primary}}>My Finances only</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Radio checked={false} theme={theme}/><span style={{fontSize:14, color:c.primary}}>Apartment 4B only</span></label>
              <label style={{display:'flex', gap:10, alignItems:'center'}}><Radio checked={false} theme={theme}/><span style={{fontSize:14, color:c.primary}}>Both</span></label>
            </div>
          </div>
        </div>
        <div style={{padding:16, background:c.surface, borderTop:`1px solid ${c.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Save" theme={theme}/>
        </div>
      </div>
    </Phone>
  );
}

function ScreenRoom({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  const accent = T.room3; // violet — this room's identity
  return (
    <Phone theme={theme} label="Room · Bali Trip">
      <div style={{height:'100%', background:c.canvas, overflowY:'auto'}}>
        <div style={{padding:'12px 16px', background:c.surface, borderBottom:`1px solid ${c.bSubtle}`}}>
          <div style={{display:'flex', alignItems:'center', gap:10}}>
            <button style={{width:36, height:36, borderRadius:'50%', background:'transparent', border:'none', color:c.primary, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.chevL} size={22}/></button>
            <div style={{width:8, height:8, borderRadius:'50%', background:accent}}/>
            <div style={{fontSize:20, fontWeight:600, color:c.primary, flex:1, letterSpacing:-0.15}}>Bali Trip</div>
            <button style={{width:36, height:36, borderRadius:'50%', background:'transparent', border:'none', color:c.primary, display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.settings} size={20}/></button>
          </div>
          <div style={{marginTop:10, display:'flex', alignItems:'center', gap:10}}>
            <AvatarStack theme={theme} members={[{initials:'A',color:accent},{initials:'M',color:T.room4},{initials:'R',color:T.room5}]}/>
            <div style={{fontSize:12, color:c.secondary}}>3 members · Alex is adding an expense…</div>
          </div>
          <div style={{marginTop:12, height:36, background:c.muted, borderRadius:12, padding:2, display:'flex', gap:2}}>
            {['Feed','Budget','Reports'].map((s,i) => (
              <div key={s} style={{flex:1, display:'flex', alignItems:'center', justifyContent:'center', fontSize:13, fontWeight:600, color:i===0?c.primary:c.secondary, background:i===0?c.surface:'transparent', borderRadius:10}}>{s}</div>
            ))}
          </div>
        </div>
        <div style={{padding:12, fontFamily:FONT}}>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:c.secondary, margin:'4px 0 8px'}}>Today</div>
          <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, overflow:'hidden'}}>
            <TxRow merchant="Bebek Bengil" cat="Dining" date="13.20" amount="Rp 285.000" theme={theme}/>
            <TxRow merchant="Taxi to villa" cat="Transport" date="11.45" amount="Rp 125.000" theme={theme} last/>
          </div>
          <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:c.secondary, margin:'12px 0 8px'}}>Yesterday</div>
          <div style={{background:c.surface, borderRadius:12, border:`1px solid ${c.bSubtle}`, overflow:'hidden'}}>
            <TxRow merchant="Grocery run" cat="Groceries" date="18.00" amount="Rp 410.000" receipt aiScanned theme={theme} last/>
          </div>
        </div>
      </div>
    </Phone>
  );
}

function ScreenPaywall({theme='light'}) {
  const c = theme==='dark' ? window.TD : window.T;
  return (
    <Phone theme={theme} label="Paywall">
      <div style={{height:'100%', background:c.canvas, display:'flex', flexDirection:'column', overflow:'hidden'}}>
        <div style={{padding:'12px 16px 0', display:'flex', justifyContent:'flex-end'}}>
          <button style={{background:'transparent', border:'none', fontSize:13, color:c.secondary, fontWeight:600}}>Not now</button>
        </div>
        <div style={{padding:'20px 20px 12px'}}>
          <div style={{fontSize:28, fontWeight:600, color:c.primary, letterSpacing:-0.3, lineHeight:'34px'}}>Unlimited budgets.<br/>Unlimited currencies.<br/>Pro.</div>
        </div>
        <div style={{padding:'0 16px', flex:1, overflowY:'auto'}}>
          {[
            ['Free','Rp 0','/mo','3 budgets, 8 scans, last 3 months reports'],
            ['Pro','Rp 85.529','/mo','Unlimited budgets · unlimited scans · CSV/PDF export', true],
            ['Team','Rp 149.000','/mo','Everything in Pro · shared rooms · admin'],
          ].map(([name, price, per, feat, rec],i) => (
            <div key={name} style={{background:c.surface, border:rec?`2px solid ${c.accent}`:`1px solid ${c.bSubtle}`, borderRadius:12, padding:14, marginBottom:10, position:'relative'}}>
              {rec && <div style={{position:'absolute', top:-10, left:12, padding:'2px 8px', background:c.accent, color:'#fff', fontSize:10, fontWeight:700, letterSpacing:0.5, textTransform:'uppercase', borderRadius:4}}>Recommended</div>}
              <div style={{display:'flex', justifyContent:'space-between', alignItems:'flex-start'}}>
                <div style={{fontSize:16, fontWeight:600, color:c.primary}}>{name}</div>
                <div style={{textAlign:'right'}}>
                  <span style={{fontSize:18, fontWeight:600, color:c.primary, fontVariantNumeric:'tabular-nums'}}>{price}</span>
                  <span style={{fontSize:12, color:c.secondary}}>{per}</span>
                </div>
              </div>
              <div style={{fontSize:12, color:c.secondary, marginTop:6, lineHeight:'17px'}}>{feat}</div>
            </div>
          ))}
          <div style={{height:36, background:c.muted, borderRadius:12, padding:2, display:'flex', gap:2, marginTop:10}}>
            {['Monthly','Yearly — 2 months free'].map((s,i) => (
              <div key={s} style={{flex:1, display:'flex', alignItems:'center', justifyContent:'center', fontSize:12, fontWeight:600, color:i===0?c.primary:c.secondary, background:i===0?c.surface:'transparent', borderRadius:10}}>{s}</div>
            ))}
          </div>
        </div>
        <div style={{padding:16, background:c.surface, borderTop:`1px solid ${c.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Start Pro — Rp 85.529/mo" theme={theme}/>
          <div style={{fontSize:11, color:c.tertiary, textAlign:'center', marginTop:8}}>Billed via Midtrans · Cancel anytime · Terms & Privacy</div>
        </div>
      </div>
    </Phone>
  );
}

function PatternBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Patterns & Screens" subtitle="Pre-composed combinations of components that solve recurring UX problems. Mobile screens assembled only from system primitives."/>
      <div style={{padding:'28px 32px', display:'flex', gap:24, flexWrap:'wrap'}}>
        <ScreenDashboard/>
        <ScreenScanReview/>
        <ScreenRoom/>
        <ScreenPaywall/>
      </div>
    </div>
  );
}

function DarkPatternBoard() {
  return (
    <div style={{background:'#0B0D0C', padding:'0 0 40px'}}>
      <Header theme="dark" title="Dark Theme · Parity" subtitle="First-class, not dimmed. Surfaces are warm dark with slight green undertone. Hero amounts stay warm off-white — never pure white. Brand shifts lighter."/>
      <div style={{padding:'28px 32px', display:'flex', gap:24, flexWrap:'wrap'}}>
        <ScreenDashboard theme="dark"/>
        <ScreenScanReview theme="dark"/>
        <ScreenRoom theme="dark"/>
        <ScreenPaywall theme="dark"/>
      </div>
    </div>
  );
}

function OfflinePatternBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Offline Pattern" subtitle="Offline is a first-class state, not an error. Persistent banner · personal entries save optimistically with 'Saved locally' affordance · Rooms show full-screen no-connection state."/>
      <div style={{padding:'24px 32px', display:'flex', gap:24, flexWrap:'wrap'}}>
        <Phone label="Offline · banner + personal still works">
          <div style={{padding:'0 16px 80px', overflowY:'auto', height:'100%', background:T.canvas}}>
            <div style={{margin:'8px -16px 10px', padding:'10px 16px', background:'#E6EEF8', color:'#2F5E99', display:'flex', alignItems:'center', gap:10}}>
              <Ico d={icons.noWifi} size={18}/>
              <div style={{fontSize:13, fontWeight:500, flex:1}}>You're offline. Personal tracking still works.</div>
              <Ico d={icons.chevR} size={16}/>
            </div>
            <div style={{fontSize:22, fontWeight:600, color:T.primary, letterSpacing:-0.2}}>Hi, Maria</div>
            <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, padding:16, marginTop:10}}>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary}}>Spent this month</div>
              <div style={{fontSize:40, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.4, marginTop:6}}>Rp 4.235.000</div>
            </div>
            <div style={{marginTop:14, fontSize:13, fontWeight:600, color:T.secondary, letterSpacing:0.3, textTransform:'uppercase'}}>Recent</div>
            <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden', marginTop:8}}>
              <div style={{display:'flex', alignItems:'center', padding:'12px 16px', gap:12, minHeight:64, borderBottom:`1px solid ${T.bSubtle}`}}>
                <CatIcon cat="Dining"/>
                <div style={{flex:1}}>
                  <div style={{fontSize:16, fontWeight:500}}>Warung Sari Rasa</div>
                  <div style={{fontSize:13, color:T.secondary, display:'flex', gap:4, alignItems:'center', marginTop:2}}>
                    <Ico d={icons.cloud} size={13} stroke="#2F5E99"/>
                    <span style={{color:'#2F5E99'}}>Saved locally</span>
                  </div>
                </div>
                <div style={{fontSize:16, fontWeight:600, fontVariantNumeric:'tabular-nums'}}>Rp 85.000</div>
              </div>
              <TxRow merchant="Shell Kemang" cat="Transport" date="Today" amount="Rp 150.000" last/>
            </div>
          </div>
        </Phone>

        <Phone label="Room · no-connection blocking state">
          <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
            <div style={{padding:'12px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
              <div style={{display:'flex', alignItems:'center', gap:8}}>
                <Ico d={icons.chevL} size={22}/>
                <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Bali Trip</div>
              </div>
            </div>
            <div style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:24, textAlign:'center'}}>
              <div style={{width:120, height:120, borderRadius:16, background:`repeating-linear-gradient(135deg, ${T.n100} 0 8px, ${T.surface} 8px 16px)`, display:'inline-flex', alignItems:'center', justifyContent:'center', marginBottom:20, border:`1px dashed ${T.bDefault}`}}>
                <Ico d={icons.noWifi} size={44} stroke={T.secondary}/>
              </div>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Rooms need internet</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px', maxWidth:240}}>Connect to see this room. Personal tracking still works.</div>
              <div style={{marginTop:20}}>
                <LoitButton size="m" label="Retry"/>
              </div>
            </div>
          </div>
        </Phone>

        <Phone label="Scanner · disabled with explanation sheet">
          <div style={{height:'100%', background:'#1F2321', position:'relative'}}>
            <div style={{position:'absolute', inset:0, background:`repeating-linear-gradient(135deg, #1F2321 0 12px, #2E3230 12px 24px)`, opacity:0.9}}/>
            <div style={{position:'absolute', top:60, left:40, right:40, border:'2px dashed rgba(255,255,255,0.3)', borderRadius:16, height:300}}/>
            <div style={{position:'absolute', bottom:0, left:0, right:0, background:T.surface, borderRadius:'24px 24px 0 0', padding:'16px 20px 24px'}}>
              <div style={{width:36, height:4, background:T.bStrong, borderRadius:999, margin:'0 auto 16px'}}/>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Scanning needs internet</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px'}}>Receipts use AI in the cloud. You can add one manually in the meantime.</div>
              <div style={{marginTop:16, display:'flex', gap:10}}>
                <LoitButton size="m" variant="secondary" fullWidth label="Retry"/>
                <LoitButton size="m" fullWidth label="Manual entry"/>
              </div>
            </div>
          </div>
        </Phone>
      </div>
    </div>
  );
}

function FormPatternBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Form Pattern" subtitle="App bar with Close · scrollable grouped fields · sticky full-width primary CTA · inline blur validation · error summary banner · unsaved-changes confirm sheet."/>
      <div style={{padding:'28px 32px', display:'flex', gap:24, flexWrap:'wrap'}}>
        <Phone label="Form · manual transaction">
          <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
            <div style={{height:52, padding:'0 8px', display:'flex', alignItems:'center', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
              <button style={{width:44, height:44, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.x} size={22}/></button>
              <div style={{fontSize:17, fontWeight:600, color:T.primary, marginLeft:4, flex:1}}>Add expense</div>
            </div>
            <div style={{padding:16, overflowY:'auto', flex:1, fontFamily:FONT}}>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, marginBottom:6}}>Basics</div>
              <LoitInput size="l" label="Amount"
                leading={<span style={{fontSize:16, fontWeight:600, color:T.secondary}}>Rp</span>}
                value="85.000"
                trailing={<span style={{padding:'4px 10px', background:T.muted, borderRadius:999, fontSize:12, fontWeight:600}}>IDR ▾</span>}/>
              <div style={{height:12}}/>
              <LoitInput label="Merchant" value="Warung Sari Rasa"/>
              <div style={{height:12}}/>
              <LoitInput label="Category" value="Dining" trailing={<Ico d={icons.chevR} size={16}/>}/>
              <div style={{height:16}}/>
              <div style={{fontSize:11, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.secondary, marginBottom:6}}>Details</div>
              <LoitInput label="Date" value="Today · 14.30"/>
              <div style={{height:12}}/>
              <LoitInput label="Notes (optional)" placeholder="Lunch with team"/>
            </div>
            <div style={{padding:16, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
              <LoitButton size="l" fullWidth label="Save expense"/>
            </div>
          </div>
        </Phone>

        <Phone label="Form · error state">
          <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
            <div style={{height:52, padding:'0 8px', display:'flex', alignItems:'center', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
              <button style={{width:44, height:44, borderRadius:'50%', background:'transparent', border:'none', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.x} size={22}/></button>
              <div style={{fontSize:17, fontWeight:600, color:T.primary, marginLeft:4, flex:1}}>Add expense</div>
            </div>
            <div style={{padding:16, flex:1, overflowY:'auto', fontFamily:FONT}}>
              <div style={{padding:'12px 14px', background:'#FBEAE9', color:'#9D332E', borderRadius:12, marginBottom:12, display:'flex', gap:10, fontSize:13, fontWeight:500}}>
                <Ico d={icons.alert} size={18}/>
                <div>Two fields need attention.</div>
              </div>
              <LoitInput size="l" label="Amount"
                leading={<span style={{fontSize:16, fontWeight:600, color:'#C5443E'}}>Rp</span>}
                value="0"
                state="error"
                error="Amount must be positive."/>
              <div style={{height:12}}/>
              <LoitInput label="Merchant" value="" state="error" error="Merchant can't be empty."/>
              <div style={{height:12}}/>
              <LoitInput label="Category" value="Dining"/>
            </div>
            <div style={{padding:16, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
              <LoitButton size="l" fullWidth label="Save expense" disabled/>
            </div>
          </div>
        </Phone>

        <Phone label="Unsaved changes · confirm sheet">
          <div style={{height:'100%', background:'rgba(0,0,0,0.40)', position:'relative'}}>
            <div style={{position:'absolute', inset:0, background:T.canvas, opacity:0.35}}/>
            <div style={{position:'absolute', bottom:0, left:0, right:0, background:T.surface, borderRadius:'24px 24px 0 0', padding:'16px 20px 24px', boxShadow:'0 -12px 32px rgba(17,22,19,0.12)'}}>
              <div style={{width:36, height:4, background:T.bStrong, borderRadius:999, margin:'0 auto 16px'}}/>
              <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15, fontFamily:FONT}}>Discard changes?</div>
              <div style={{fontSize:14, color:T.secondary, marginTop:8, lineHeight:'20px', fontFamily:FONT}}>Your expense hasn't been saved yet.</div>
              <div style={{display:'flex', gap:10, marginTop:20}}>
                <LoitButton size="m" variant="secondary" label="Keep editing" fullWidth/>
                <LoitButton size="m" variant="destructive.solid" label="Discard" fullWidth/>
              </div>
            </div>
          </div>
        </Phone>
      </div>
    </div>
  );
}

function VoiceBoard() {
  const pairs = [
    ['Success','One or two words','Saved. · Done. · Welcome to Pro.'],
    ['Inline error','Cause + fix','Amount must be positive.'],
    ['Destructive confirm','What + irreversibility',"Delete transaction? This can't be undone."],
    ['Empty state','Invitation + action','No expenses yet. Snap your first receipt.'],
    ['Offline','Status + reassurance',"You're offline. Personal tracking still works."],
    ['Paywall','Value-first headline','Unlimited budgets. Unlimited currencies. Pro.'],
  ];
  const forbidden = [
    '"Oops!", "Uh oh!", "Whoops!"',
    'Exclamation points on destructive or error copy',
    'Emoji in error or system messages',
    '"please" in instructions — it implies supplication',
    'Question marks on success messages',
    '"Congratulations!" — say what the user achieved instead',
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Voice & Content" subtitle="Voice is part of the system. Warm, direct, competent. Never cute, never cold. Human numbers. Active verbs. Second-person you."/>
      <div style={{padding:'24px 32px', display:'grid', gridTemplateColumns:'1fr 1fr', gap:24}}>
        <div>
          <Label>Copy Patterns</Label>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
            {pairs.map(([s,p,ex], i) => (
              <div key={s} style={{padding:'14px 16px', borderTop:i===0?'none':`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
                <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.brand}}>{s}</div>
                <div style={{fontSize:13, color:T.secondary, marginTop:2}}>{p}</div>
                <div style={{fontSize:14, color:T.primary, marginTop:6, fontWeight:500, fontStyle:'italic'}}>"{ex}"</div>
              </div>
            ))}
          </div>
        </div>
        <div>
          <Label>Forbidden Copy Patterns</Label>
          <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:18, fontFamily:FONT}}>
            {forbidden.map((f,i) => (
              <div key={i} style={{display:'flex', alignItems:'flex-start', gap:10, padding:'8px 0', borderBottom:i===forbidden.length-1?'none':`1px solid ${T.bSubtle}`}}>
                <div style={{width:20, height:20, borderRadius:'50%', background:'#FBEAE9', color:'#9D332E', display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0, marginTop:1}}>
                  <Ico d={icons.x} size={14} sw={2.5}/>
                </div>
                <div style={{fontSize:13, color:T.primary, lineHeight:'18px'}}>{f}</div>
              </div>
            ))}
          </div>
          <div style={{marginTop:16, padding:16, background:T.muted, borderRadius:12, fontFamily:FONT}}>
            <div style={{fontSize:13, fontWeight:600, color:T.primary, marginBottom:6}}>Numeric Copy Rules</div>
            <ul style={{margin:0, paddingLeft:18, fontSize:13, color:T.secondary, lineHeight:'22px'}}>
              <li>Currency formatting: always locale-aware via <code style={{fontFamily:MONO, fontSize:12}}>intl</code>.</li>
              <li>Large numbers (reports): abbreviate with thin spaces — "Rp1.2jt" (ID) / "$1.2K" (EN).</li>
              <li>Percentages: no decimals unless &lt; 1% ("12%" not "12.0%").</li>
              <li>Time: relative for recent ("2 min ago", "Yesterday"), absolute for &gt; 1 week.</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

function LocalizationBoard() {
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Localization" subtitle="English and Bahasa Indonesia are co-primary. Every string, every screen, day one. Indonesian runs 15–25% longer; components accommodate up to 1.3× English length."/>
      <div style={{padding:'24px 32px'}}>
        <Label>Locale-Aware Tokens</Label>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden', marginBottom:24}}>
          <div style={{display:'grid', gridTemplateColumns:'1.2fr 1fr 1fr', padding:'10px 16px', background:T.muted, fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', fontFamily:FONT}}>
            <div>Token</div><div>EN (en_US)</div><div>ID (id_ID)</div>
          </div>
          {[
            ['Decimal separator', '.', ','],
            ['Thousand separator', ',', '.'],
            ['Date long', 'Dec 12, 2026', '12 Des 2026'],
            ['Date short', '12/12/2026', '12/12/2026'],
            ['First day of week', 'Sunday', 'Monday'],
            ['Currency (default)', '$1,234.56', 'Rp 1.234.560'],
          ].map(([t,e,i], k) => (
            <div key={t} style={{display:'grid', gridTemplateColumns:'1.2fr 1fr 1fr', padding:'12px 16px', borderTop:`1px solid ${T.bSubtle}`, fontFamily:FONT, fontSize:13, color:T.primary}}>
              <div style={{fontWeight:500}}>{t}</div>
              <div style={{fontFamily:MONO, color:T.secondary}}>{e}</div>
              <div style={{fontFamily:MONO, color:T.secondary}}>{i}</div>
            </div>
          ))}
        </div>

        <Label>Length Tolerance · side-by-side</Label>
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:16}}>
          {[
            ['English', [['Save expense', 'primary'],['Set a monthly budget', 'secondary'],["You're offline. Personal tracking still works.", 'banner']]],
            ['Bahasa Indonesia', [['Simpan pengeluaran', 'primary'],['Atur anggaran bulanan', 'secondary'],['Kamu sedang offline. Pelacakan pribadi tetap bisa dipakai.', 'banner']]],
          ].map(([lang, items]) => (
            <div key={lang} style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, padding:16, fontFamily:FONT}}>
              <div style={{fontSize:12, fontWeight:600, letterSpacing:0.5, textTransform:'uppercase', color:T.tertiary, marginBottom:10}}>{lang}</div>
              {items.map(([copy, kind], i) => (
                <div key={i} style={{marginBottom:10}}>
                  {kind==='primary' && <LoitButton size="m" fullWidth label={copy}/>}
                  {kind==='secondary' && <LoitButton size="m" variant="secondary" fullWidth label={copy}/>}
                  {kind==='banner' && (
                    <div style={{padding:'12px 14px', background:'#E6EEF8', color:'#2F5E99', borderRadius:12, fontSize:13, fontWeight:500, display:'flex', gap:10, alignItems:'center'}}>
                      <Ico d={icons.noWifi} size={16}/><span>{copy}</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function PlatformBoard() {
  const rows = [
    ['Back navigation', 'Swipe from left edge · leading <', 'System back · leading ←'],
    ['Page transition', 'Slide from right', 'Slide from right (matched)'],
    ['Modal presentation', 'Custom bottom sheet', 'Custom bottom sheet (same)'],
    ['Date picker', 'Wheel picker in sheet', 'Material calendar'],
    ['Time picker', 'Wheel picker', 'Material clock'],
    ['Haptics', 'HapticFeedback.lightImpact / selectionClick', 'Matched vibration'],
    ['Permission UI', 'Apple HIG copy', 'Material copy'],
    ['Share', 'UIActivityViewController', 'Intent.ACTION_SEND'],
    ['Biometric prompt', 'Face ID / Touch ID', 'Fingerprint / Face unlock'],
    ['Sign-in with Apple', 'Required, shown', 'Not shown'],
    ['Google Sign-in', 'Shown', 'Shown (primary)'],
    ['App icon', 'Squircle, iOS template', 'Adaptive icon (foreground + background)'],
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Platform Adaptation" subtitle="One visual design on both platforms. Only platform-native behavior differs where OS expectation matters. Everything not on this list — colors, typography, spacing, components, motion — is identical."/>
      <div style={{padding:'24px 32px'}}>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, overflow:'hidden'}}>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1.2fr 1.2fr', padding:'10px 16px', background:T.muted, fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.5, textTransform:'uppercase', fontFamily:FONT}}>
            <div>Concern</div><div>iOS</div><div>Android</div>
          </div>
          {rows.map(([c,i,a], k) => (
            <div key={c} style={{display:'grid', gridTemplateColumns:'1fr 1.2fr 1.2fr', padding:'12px 16px', borderTop:`1px solid ${T.bSubtle}`, fontFamily:FONT, fontSize:13}}>
              <div style={{color:T.primary, fontWeight:500}}>{c}</div>
              <div style={{color:T.secondary}}>{i}</div>
              <div style={{color:T.secondary}}>{a}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ChecklistBoard() {
  const items = [
    'Uses only tokens from this document (no raw hex, pixel, or duration values)',
    'Renders correctly in light and dark themes',
    'Renders correctly in English and Bahasa Indonesia at max string length',
    'All five states designed: empty, loading, error-recoverable, error-blocking, success',
    'Motion spec defined and reduce-motion respected',
    'Accessibility: semantic labels, 44pt hit targets, contrast verified',
    'Offline behavior defined',
    'Haptic feedback assigned where appropriate',
    'Reviewed against system principles',
    'Does not introduce a new variant of an existing component without proposal',
  ];
  return (
    <div style={{background:T.canvas, padding:'0 0 40px'}}>
      <Header title="Acceptance Checklist" subtitle='"Does this ship with LOIT?" Every new screen or component passes this gate before merge.'/>
      <div style={{padding:'24px 32px'}}>
        <div style={{background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:16, padding:24, fontFamily:FONT}}>
          {items.map((it, i) => (
            <div key={i} style={{display:'flex', gap:14, alignItems:'flex-start', padding:'12px 0', borderBottom:i===items.length-1?'none':`1px solid ${T.bSubtle}`}}>
              <div style={{width:22, height:22, borderRadius:6, border:`1.5px solid ${T.bStrong}`, background:'transparent', flexShrink:0, marginTop:1}}/>
              <div style={{fontSize:14, color:T.primary, lineHeight:'22px'}}>{it}</div>
            </div>
          ))}
        </div>
        <div style={{marginTop:20, textAlign:'center', fontFamily:FONT, fontSize:13, color:T.tertiary, fontStyle:'italic'}}>
          LOIT Design System · Split bills, not friendships. · Version 1.0.0
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {PatternBoard, DarkPatternBoard, OfflinePatternBoard, FormPatternBoard, VoiceBoard, LocalizationBoard, PlatformBoard, ChecklistBoard});
