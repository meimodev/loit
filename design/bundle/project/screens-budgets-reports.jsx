// Budgets screens + Reports/Insights — layout DNA from references applied:
// AppBarMonth + StatTriple + edge-to-edge LineRow lists, FabStack on tab-bar screens.

function BudgetsList() {
  const list = [
    ['Dining', 82, 'Rp 1.640.000', 'Rp 2.000.000', '#F2A85C'],
    ['Groceries', 48, 'Rp 960.000', 'Rp 2.000.000', '#2F8F5E'],
    ['Transport', 125, 'Rp 1.250.000', 'Rp 1.000.000', '#3E7AC5'],
    ['Shopping', 32, 'Rp 320.000', 'Rp 1.000.000', '#B15FC0'],
    ['Entertainment', 60, 'Rp 300.000', 'Rp 500.000', '#E06B8A'],
  ];
  return (
    <PhoneS label="01 · Budgets list" caption="Stat triple · grouped list · edge-to-edge rows">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['plus','filter','more']}/>
        <TabStrip tabs={['Monthly','Weekly','Custom']} active={0}/>
        <StatTriple stats={[
          ['Limit','Rp 6.500k','#3E7AC5'],
          ['Spent','Rp 4.470k','#C5443E'],
          ['Left','Rp 2.030k', T.primary],
        ]}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <GroupLabel>Categories <span style={{float:'right', color:T.tertiary, fontWeight:500}}>Day 18 · 30 — on pace</span></GroupLabel>
          {list.map(([n, p, s, t, col], i, arr) => {
            const ic = CAT_ICON[n] || 'more';
            const over = p >= 100;
            return (
              <div key={n} style={{display:'flex', alignItems:'center', padding:'12px 16px', gap:12,
                borderBottom:i===arr.length-1?'none':`1px solid ${T.bSubtle}`, background:T.surface, fontFamily:FONT}}>
                <div style={{width:36, height:36, borderRadius:8, background:col+'24', color:col, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
                  <Ico d={icons[ic]} size={18}/>
                </div>
                <div style={{flex:1, minWidth:0}}>
                  <div style={{display:'flex', justifyContent:'space-between', fontSize:14, color:T.primary, fontWeight:500}}>
                    <span>{n}</span>
                    <span style={{fontWeight:600, color:over?'#C5443E':T.primary, fontVariantNumeric:'tabular-nums'}}>{p}%</span>
                  </div>
                  <div style={{marginTop:5, height:4, background:T.muted, borderRadius:999, overflow:'hidden'}}>
                    <div style={{width:Math.min(100,p)+'%', height:'100%', background:over?'#C5443E':col}}/>
                  </div>
                  <div style={{display:'flex', justifyContent:'space-between', marginTop:4, fontSize:11, color:T.tertiary, fontVariantNumeric:'tabular-nums'}}>
                    <span>{s} of {t}</span>
                    <span style={{color: over?'#9D332E':T.tertiary, fontWeight: over?600:400}}>{over?'Rp 250k over':''}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        <FabStack primaryColor={T.accent}/>
        <TabBar active="more"/>
      </div>
    </PhoneS>
  );
}

function BudgetCreate() {
  return (
    <PhoneS label="02 · Create budget" caption="Numeric keypad-friendly · category + period + alerts">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="New budget" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto', padding:'0 0 16px'}}>
          <div style={{textAlign:'center', padding:'16px 0 22px', fontFamily:FONT, background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
            <div style={{fontSize:13, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase'}}>Limit</div>
            <div style={{fontSize:44, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', letterSpacing:-0.5, marginTop:4}}>
              <span style={{fontSize:20, color:T.secondary, marginRight:4}}>Rp</span>2.000.000
            </div>
          </div>
          <GroupLabel>Setup</GroupLabel>
          <LineRow label="Category" value="Dining" leading={<div style={{width:32, height:32, borderRadius:8, background:'#F2A85C24', color:'#F2A85C', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.utensils} size={16}/></div>}/>
          <LineRow label="Period" value="Monthly · 1st"/>
          <LineRow label="Resets on" value="Day 1"/>

          <GroupLabel>Alerts</GroupLabel>
          {[['At 70%', true],['At 100%', true],['Daily over budget', false]].map(([k,v],i,a) => (
            <div key={k} style={{padding:'14px 16px', display:'flex', alignItems:'center', borderBottom:`1px solid ${T.bSubtle}`, background:T.surface, fontFamily:FONT}}>
              <div style={{flex:1, fontSize:14, color:T.primary}}>{k}</div>
              <Toggle on={v}/>
            </div>
          ))}

          <div style={{margin:'14px 16px 0', padding:12, background:T.teal50, borderRadius:12, fontFamily:FONT, fontSize:12, color:T.teal800, display:'flex', gap:10}}>
            <Ico d={icons.info} size={16} stroke={T.teal700}/>
            <div>You'll see this in Personal only. Room budgets are set in each room.</div>
          </div>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Create budget"/>
        </div>
      </div>
    </PhoneS>
  );
}

function BudgetDetail() {
  return (
    <PhoneS label="03 · Budget detail · over" caption="Drill-in · spend pattern · contributing transactions">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="" leading={<BackBtn/>} trailing={<IconBtn d={icons.more}/>}/>
        <div style={{flex:1, overflowY:'auto'}}>
          <div style={{padding:'8px 20px 20px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
            <div style={{display:'flex', alignItems:'center', gap:10}}>
              <div style={{width:40, height:40, borderRadius:8, background:'#3E7AC524', color:'#3E7AC5', display:'inline-flex', alignItems:'center', justifyContent:'center'}}><Ico d={icons.car} size={20}/></div>
              <div>
                <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase'}}>Transport · Monthly</div>
                <div style={{fontSize:20, fontWeight:600, color:T.primary, letterSpacing:-0.15}}>Rp 1.250.000 <span style={{fontSize:13, fontWeight:500, color:T.secondary}}>/ 1.000.000</span></div>
              </div>
            </div>
            <div style={{marginTop:14, height:5, background:T.muted, borderRadius:999, overflow:'hidden'}}>
              <div style={{width:'100%', height:'100%', background:'#C5443E'}}/>
            </div>
            <div style={{display:'flex', justifyContent:'space-between', marginTop:6, fontSize:12, color:'#9D332E', fontWeight:600}}>
              <span>125% — Rp 250.000 over</span><span>Day 18 / 30</span>
            </div>
          </div>
          <GroupLabel>Daily spend · last 14 days</GroupLabel>
          <div style={{padding:'12px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`}}>
            <div style={{display:'flex', alignItems:'flex-end', gap:5, height:80}}>
              {[20,35,15,55,40,25,80,45,30,70,50,90,65,75].map((h,i) => (
                <div key={i} style={{flex:1, height:`${h}%`, background:i>=11?'#C5443E':T.brand, borderRadius:'3px 3px 0 0', opacity:i<11?0.7:1}}/>
              ))}
            </div>
            <div style={{display:'flex', justifyContent:'space-between', marginTop:8, fontSize:10, color:T.tertiary, fontFamily:MONO}}>
              <span>5 Nov</span><span>12 Nov</span><span>18 Nov</span>
            </div>
          </div>
          <GroupLabel>Contributing · top 5</GroupLabel>
          <TxLine cat="Transport" merchant="Shell Kemang" account="BCA · Today" amount="Rp 150.000"/>
          <TxLine cat="Transport" merchant="Grab to office" account="Gopay · Yesterday" amount="Rp 28.500"/>
          <TxLine cat="Transport" merchant="Pertamina" account="Cash · Sun" amount="Rp 350.000"/>
          <TxLine cat="Transport" merchant="Toll Jagorawi" account="E-Money · Sat" amount="Rp 95.000"/>
          <TxLine cat="Transport" merchant="Grab to mall" account="Gopay · Fri" amount="Rp 32.500"/>
          <div style={{height:80}}/>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`, display:'flex', gap:10}}>
          <LoitButton size="m" variant="secondary" label="Edit limit" fullWidth/>
          <LoitButton size="m" label="Roll over" fullWidth/>
        </div>
      </div>
    </PhoneS>
  );
}

function BudgetsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="F · Budgets" title="Plan, track, drill-in" subtitle="List w/ stat triple + grouped edge-to-edge rows · create with alerts · drill-in with spend pattern + contributing txs."/>
      <ScreensGrid>
        <BudgetsList/>
        <BudgetCreate/>
        <BudgetDetail/>
      </ScreensGrid>
    </div>
  );
}

// ─────────── Reports / Insights ───────────

function ReportsOverview() {
  return (
    <PhoneS label="01 · Reports · overview" caption="Month nav · stat triple · category breakdown">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBarMonth label="Nov 2026" leading={<div style={{width:14}}/>} actions={['filter','more']}/>
        <TabStrip tabs={['Overview','Categories','Trend','Compare']} active={0}/>
        <StatTriple stats={[
          ['Income','Rp 8.500k','#3E7AC5'],
          ['Expenses','Rp 4.235k','#C5443E'],
          ['Net','Rp 4.265k', T.primary],
        ]}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <GroupLabel>Trend · 30 days</GroupLabel>
          <div style={{padding:'14px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
            <div style={{display:'flex', justifyContent:'space-between', marginBottom:8}}>
              <div>
                <div style={{fontSize:11, color:T.secondary, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase'}}>Avg/day</div>
                <div style={{fontSize:20, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums', marginTop:2}}>Rp 235k</div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontSize:11, color:T.secondary, fontWeight:600, letterSpacing:0.4, textTransform:'uppercase'}}>Trend</div>
                <div style={{fontSize:14, fontWeight:600, color:'#2F8F5E', marginTop:2, display:'inline-flex', alignItems:'center', gap:4}}><Ico d={icons.arrowDown} size={12}/> 8% lower</div>
              </div>
            </div>
            <div style={{height:90, position:'relative'}}>
              <svg viewBox="0 0 300 100" width="100%" height="100%" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="ar" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0" stopColor="#0F6E5C" stopOpacity="0.25"/>
                    <stop offset="1" stopColor="#0F6E5C" stopOpacity="0"/>
                  </linearGradient>
                </defs>
                <path d="M0,80 L20,72 L40,75 L60,55 L80,60 L100,40 L120,48 L140,32 L160,42 L180,28 L200,38 L220,22 L240,30 L260,18 L280,26 L300,12 L300,100 L0,100 Z" fill="url(#ar)"/>
                <path d="M0,80 L20,72 L40,75 L60,55 L80,60 L100,40 L120,48 L140,32 L160,42 L180,28 L200,38 L220,22 L240,30 L260,18 L280,26 L300,12" fill="none" stroke="#0F6E5C" strokeWidth="2"/>
              </svg>
            </div>
          </div>
          <GroupLabel>By category</GroupLabel>
          <div style={{padding:'12px 16px 4px', background:T.surface}}>
            <div style={{display:'flex', borderRadius:6, overflow:'hidden', height:14}}>
              <div style={{flex:38, background:'#F2A85C'}}/><div style={{flex:22, background:'#2F8F5E'}}/><div style={{flex:18, background:'#3E7AC5'}}/><div style={{flex:12, background:'#B15FC0'}}/><div style={{flex:10, background:'#5A6160'}}/>
            </div>
          </div>
          {[['Dining','#F2A85C','Rp 1.6jt','38%'],['Groceries','#2F8F5E','Rp 960k','22%'],['Transport','#3E7AC5','Rp 760k','18%'],['Shopping','#B15FC0','Rp 510k','12%'],['Other','#5A6160','Rp 410k','10%']].map(([n,col,a,p],i,arr) => (
            <div key={n} style={{display:'flex', alignItems:'center', padding:'12px 16px', gap:10,
              borderBottom:i===arr.length-1?'none':`1px solid ${T.bSubtle}`, background:T.surface, fontFamily:FONT}}>
              <div style={{width:8, height:8, borderRadius:2, background:col}}/>
              <div style={{flex:1, fontSize:14, color:T.primary}}>{n}</div>
              <div style={{fontSize:14, fontWeight:600, color:T.primary, fontVariantNumeric:'tabular-nums'}}>{a}</div>
              <div style={{fontSize:12, color:T.tertiary, fontVariantNumeric:'tabular-nums', width:40, textAlign:'right'}}>{p}</div>
            </div>
          ))}
        </div>
        <TabBar active="more"/>
      </div>
    </PhoneS>
  );
}

function ReportsInsights() {
  const cards = [
    ['Dining is up 28% vs October','#F2A85C','utensils','Most spent at Warung Sari Rasa (4 visits, Rp 340.000)'],
    ['You saved Rp 180.000 on transport','#2F8F5E','arrowDown','Switched to Grab Subscribe — keep it up.'],
    ['3 unused subscriptions','#D49A2B','plug','Apple Music, Spotify Premium, Notion. Tap to review.'],
  ];
  return (
    <PhoneS label="02 · Insights" caption="AI-flavored cards · always actionable">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Insights" trailing={<span style={{padding:'4px 8px', margin:8, background:T.teal50, color:T.brand, fontSize:10, fontWeight:600, borderRadius:4, letterSpacing:0.4, textTransform:'uppercase'}}>Beta</span>}/>
        <div style={{flex:1, overflowY:'auto', paddingBottom:TAB_PAD}}>
          <div style={{padding:'14px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, fontFamily:FONT}}>
            <div style={{fontSize:11, fontWeight:600, color:T.secondary, letterSpacing:0.4, textTransform:'uppercase'}}>This week</div>
            <div style={{fontSize:18, fontWeight:600, color:T.primary, marginTop:4, lineHeight:'24px', letterSpacing:-0.1}}>You're spending evenly across categories — your most balanced week this month.</div>
          </div>
          <GroupLabel>Insights · 3</GroupLabel>
          {cards.map(([t,col,ic,d],i,arr) => (
            <div key={t} style={{padding:'14px 16px', background:T.surface, borderBottom:i===arr.length-1?'none':`1px solid ${T.bSubtle}`, display:'flex', gap:12, fontFamily:FONT, position:'relative'}}>
              <div style={{position:'absolute', left:0, top:0, bottom:0, width:3, background:col}}/>
              <div style={{width:32, height:32, borderRadius:8, background:col+'24', color:col, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0}}><Ico d={icons[ic]} size={16}/></div>
              <div style={{flex:1, minWidth:0}}>
                <div style={{fontSize:14, fontWeight:600, color:T.primary, lineHeight:'18px'}}>{t}</div>
                <div style={{fontSize:12, color:T.secondary, marginTop:4, lineHeight:'17px'}}>{d}</div>
                <div style={{marginTop:8, fontSize:12, color:T.brand, fontWeight:600}}>See details →</div>
              </div>
            </div>
          ))}
        </div>
        <TabBar active="more"/>
      </div>
    </PhoneS>
  );
}

function ReportsExport() {
  return (
    <PhoneS label="03 · Export · Pro" caption="Choose period · format · filter · destination">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Export" leading={<CloseBtn/>}/>
        <div style={{flex:1, overflowY:'auto'}}>
          <GroupLabel>Period</GroupLabel>
          <LineRow label="Range" value="01 — 30 Nov 2026"/>
          <LineRow label="Compare to" value="Off" valueColor={T.tertiary}/>

          <GroupLabel>Format</GroupLabel>
          <div style={{padding:'12px 16px', background:T.surface, borderBottom:`1px solid ${T.bSubtle}`, display:'flex', gap:10, fontFamily:FONT}}>
            {[['CSV','data',true],['PDF','report',false],['Image','share',false]].map(([n,d,sel]) => (
              <div key={n} style={{flex:1, padding:14, background:sel?T.teal50:T.canvas, border:`1.5px solid ${sel?T.brand:T.bSubtle}`, borderRadius:10, textAlign:'center'}}>
                <div style={{fontSize:14, fontWeight:600, color:sel?T.teal800:T.primary}}>{n}</div>
                <div style={{fontSize:11, color:T.secondary, marginTop:2}}>{d}</div>
              </div>
            ))}
          </div>

          <GroupLabel>Include</GroupLabel>
          {[['All transactions',true],['Receipts',true],['Categories',true],['Notes',false]].map(([k,v],i,a) => (
            <label key={k} style={{padding:'14px 16px', display:'flex', alignItems:'center', borderBottom:`1px solid ${T.bSubtle}`, background:T.surface, fontFamily:FONT}}>
              <Checkbox checked={v}/>
              <span style={{flex:1, fontSize:14, color:T.primary, marginLeft:10}}>{k}</span>
            </label>
          ))}

          <div style={{margin:'14px 16px 0', padding:12, background:T.muted, borderRadius:12, fontSize:12, color:T.secondary, display:'flex', gap:10, fontFamily:FONT}}>
            <Ico d={icons.info} size={16} stroke={T.brand}/>
            <div>Export goes to <strong style={{color:T.primary}}>maria@example.com</strong>. Files larger than 10 MB are linked.</div>
          </div>
          <div style={{height:20}}/>
        </div>
        <div style={{padding:14, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Export 142 transactions"/>
        </div>
      </div>
    </PhoneS>
  );
}

function ReportsArtboard() {
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="G · Reports & Insights" title="Make sense of money — without becoming a dashboard" subtitle="Period overview w/ stat triple · category breakdown as edge-to-edge list · AI insight cards · Pro export."/>
      <ScreensGrid>
        <ReportsOverview/>
        <ReportsInsights/>
        <ReportsExport/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {BudgetsArtboard, ReportsArtboard});
