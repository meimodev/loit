// Onboarding, Auth, Setup screens

function ScreenSplash() {
  return (
    <PhoneS label="01 · Splash" caption="Brand teal. Logo + wordmark. 800ms hold.">
      <div style={{height:'100%', background:T.teal700, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', color:'#fff'}}>
        <div style={{width:80, height:80, borderRadius:20, background:T.ochre400, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:FONT, fontSize:42, fontWeight:700, color:T.teal800, letterSpacing:-1}}>L</div>
        <div style={{fontFamily:FONT, fontSize:40, fontWeight:600, letterSpacing:-1, marginTop:20}}>LOIT</div>
        <div style={{fontFamily:FONT, fontSize:13, color:T.teal100, marginTop:8, letterSpacing:0.3}}>Split bills, not friendships.</div>
      </div>
    </PhoneS>
  );
}

function WelcomeSlide({idx, title, body, illustration}) {
  return (
    <PhoneS label={`02.${idx} · Welcome`} caption={title}>
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column', padding:'40px 24px 24px'}}>
        <div style={{flex:1, display:'flex', alignItems:'center', justifyContent:'center'}}>
          <div style={{width:240, height:240, borderRadius:24, background:`linear-gradient(145deg, ${T.teal50}, ${T.ochre50})`, border:`1px solid ${T.bSubtle}`, display:'flex', alignItems:'center', justifyContent:'center', color:T.brand, position:'relative'}}>
            {illustration}
          </div>
        </div>
        <div style={{display:'flex', gap:6, justifyContent:'center', margin:'20px 0 16px'}}>
          {[0,1,2].map(i => (
            <div key={i} style={{width: i===idx?24:6, height:6, borderRadius:999, background: i===idx?T.brand:T.bDefault}}/>
          ))}
        </div>
        <div style={{fontSize:24, fontWeight:600, color:T.primary, letterSpacing:-0.3, textAlign:'center', lineHeight:'30px', fontFamily:FONT}}>{title}</div>
        <div style={{fontSize:14, color:T.secondary, textAlign:'center', marginTop:8, lineHeight:'20px', fontFamily:FONT, maxWidth:280, margin:'8px auto 0'}}>{body}</div>
        <div style={{marginTop:20}}>
          <LoitButton size="l" fullWidth label={idx===2?'Get started':'Next'}/>
          <div style={{textAlign:'center', marginTop:10, fontSize:13, color:T.secondary, fontFamily:FONT, fontWeight:600}}>{idx<2?'Skip':'Sign in instead'}</div>
        </div>
      </div>
    </PhoneS>
  );
}

function ScreenSignUp() {
  return (
    <PhoneS label="03 · Sign up" caption="Social-first. Email is secondary.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column', padding:'20px 20px 24px'}}>
        <div style={{fontSize:13, color:T.secondary, fontFamily:FONT, fontWeight:600}}>LOIT</div>
        <div style={{marginTop:'auto'}}>
          <div style={{fontSize:30, fontWeight:600, color:T.primary, letterSpacing:-0.3, lineHeight:'36px', fontFamily:FONT}}>Let's get you<br/>started.</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:8, fontFamily:FONT}}>Free forever. Upgrade anytime.</div>
          <div style={{marginTop:24, display:'flex', flexDirection:'column', gap:10}}>
            <button style={{height:52, background:T.surface, border:`1.5px solid ${T.bStrong}`, borderRadius:12, fontSize:15, fontWeight:600, color:T.primary, fontFamily:FONT, display:'flex', alignItems:'center', justifyContent:'center', gap:10}}>
              <div style={{width:20, height:20, borderRadius:4, background:'linear-gradient(135deg, #EA4335, #4285F4, #34A853, #FBBC05)'}}/>
              Continue with Google
            </button>
            <button style={{height:52, background:T.n900, border:'none', borderRadius:12, fontSize:15, fontWeight:600, color:'#fff', fontFamily:FONT, display:'flex', alignItems:'center', justifyContent:'center', gap:10}}>
              
              Continue with Apple
            </button>
            <button style={{height:52, background:'transparent', border:`1.5px solid ${T.bDefault}`, borderRadius:12, fontSize:15, fontWeight:600, color:T.primary, fontFamily:FONT}}>
              Continue with email
            </button>
          </div>
          <div style={{fontSize:11, color:T.tertiary, textAlign:'center', marginTop:20, lineHeight:'16px', fontFamily:FONT}}>By continuing you agree to our <span style={{color:T.brand, fontWeight:600}}>Terms</span> and <span style={{color:T.brand, fontWeight:600}}>Privacy</span>.</div>
          <div style={{textAlign:'center', fontSize:14, color:T.secondary, marginTop:16, fontFamily:FONT}}>Already have an account? <span style={{color:T.brand, fontWeight:600}}>Sign in</span></div>
        </div>
      </div>
    </PhoneS>
  );
}

function ScreenSignIn() {
  return (
    <PhoneS label="04 · Sign in · email" caption="Email+password fallback.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Sign in" leading={<BackBtn/>}/>
        <div style={{padding:24, flex:1}}>
          <div style={{fontSize:24, fontWeight:600, color:T.primary, letterSpacing:-0.2, fontFamily:FONT}}>Welcome back</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:6, fontFamily:FONT}}>Sign in to your account</div>
          <div style={{marginTop:24}}>
            <LoitInput label="Email" value="maria@gmail.com"/>
            <div style={{height:16}}/>
            <LoitInput label="Password" value="••••••••" trailing={<Ico d={icons.eye} size={18}/>}/>
            <div style={{textAlign:'right', marginTop:10, fontSize:13, color:T.brand, fontWeight:600, fontFamily:FONT}}>Forgot password?</div>
          </div>
        </div>
        <div style={{padding:20, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Sign in"/>
        </div>
      </div>
    </PhoneS>
  );
}

function ScreenOTP() {
  return (
    <PhoneS label="05 · Verify email" caption="6-digit code. Numeric keypad opens.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="" leading={<BackBtn/>}/>
        <div style={{padding:24, flex:1}}>
          <div style={{fontSize:24, fontWeight:600, color:T.primary, letterSpacing:-0.2, fontFamily:FONT}}>Check your email</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:6, lineHeight:'20px', fontFamily:FONT}}>We sent a 6-digit code to<br/><b style={{color:T.primary}}>maria@gmail.com</b></div>
          <div style={{display:'flex', gap:8, marginTop:28, justifyContent:'space-between'}}>
            {['4','2','1','9','·','·'].map((v,i) => (
              <div key={i} style={{flex:1, height:56, borderRadius:12, border:`${i===4?2:1}px solid ${i===4?T.bFocus:T.bDefault}`, background:T.surface, display:'flex', alignItems:'center', justifyContent:'center', fontSize:22, fontWeight:600, color:i>3?T.tertiary:T.primary, fontFamily:FONT, fontVariantNumeric:'tabular-nums'}}>{v==='·'?'':v}</div>
            ))}
          </div>
          <div style={{marginTop:20, fontSize:13, color:T.secondary, textAlign:'center', fontFamily:FONT}}>Didn't get it? <span style={{color:T.brand, fontWeight:600}}>Resend in 0:42</span></div>
        </div>
      </div>
    </PhoneS>
  );
}

function ScreenRegion() {
  return (
    <PhoneS label="06 · Region & currency" caption="First-run setup. Detected via IP.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Your setup" subtitle="Step 1 of 2"/>
        <div style={{padding:24, flex:1, overflowY:'auto'}}>
          <div style={{fontSize:22, fontWeight:600, color:T.primary, letterSpacing:-0.2, fontFamily:FONT}}>Where are you based?</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:6, fontFamily:FONT}}>Sets default currency, date format, and language.</div>
          <div style={{marginTop:20}}>
            <LoitInput label="Country" value="🇮🇩 Indonesia" trailing={<Ico d={icons.chevR} size={16}/>}/>
            <div style={{height:14}}/>
            <LoitInput label="Home currency" value="Rupiah · Rp · IDR" trailing={<Ico d={icons.chevR} size={16}/>} helper="You can track in multiple currencies later."/>
            <div style={{height:14}}/>
            <LoitInput label="Language" value="Bahasa Indonesia" trailing={<Ico d={icons.chevR} size={16}/>}/>
          </div>
          <div style={{marginTop:24, padding:14, background:T.teal50, borderRadius:12, fontFamily:FONT, display:'flex', gap:10, alignItems:'flex-start'}}>
            <div style={{color:T.brand, marginTop:1}}><Ico d={icons.info} size={18}/></div>
            <div style={{fontSize:13, color:T.teal800, lineHeight:'18px'}}>We detected these settings. You can change any later in Settings.</div>
          </div>
        </div>
        <div style={{padding:20, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Continue"/>
        </div>
      </div>
    </PhoneS>
  );
}

function ScreenPerms() {
  return (
    <PhoneS label="07 · Permissions" caption="Camera + notifications. Honest about why.">
      <div style={{height:'100%', background:T.canvas, display:'flex', flexDirection:'column'}}>
        <AppBar title="Almost there" subtitle="Step 2 of 2"/>
        <div style={{padding:24, flex:1}}>
          <div style={{fontSize:22, fontWeight:600, color:T.primary, letterSpacing:-0.2, fontFamily:FONT}}>Two quick permissions</div>
          <div style={{fontSize:14, color:T.secondary, marginTop:6, fontFamily:FONT}}>We'll ask each when you need it — you can skip now.</div>
          {[
            ['camera','Camera','So you can snap receipts. Stored encrypted, deleted on request.'],
            ['alert','Notifications','Budget alerts and room activity. Turn off anytime.'],
          ].map(([ic,n,why],i) => (
            <div key={n} style={{marginTop:16, padding:16, background:T.surface, border:`1px solid ${T.bSubtle}`, borderRadius:12, fontFamily:FONT, display:'flex', gap:12, alignItems:'flex-start'}}>
              <div style={{width:40, height:40, borderRadius:'50%', background:T.teal50, color:T.brand, display:'inline-flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
                <Ico d={icons[ic]} size={20}/>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:15, fontWeight:600, color:T.primary}}>{n}</div>
                <div style={{fontSize:13, color:T.secondary, marginTop:3, lineHeight:'18px'}}>{why}</div>
              </div>
              <Toggle on={i===0}/>
            </div>
          ))}
        </div>
        <div style={{padding:20, background:T.surface, borderTop:`1px solid ${T.bSubtle}`}}>
          <LoitButton size="l" fullWidth label="Start using LOIT"/>
        </div>
      </div>
    </PhoneS>
  );
}

function OnboardingArtboard() {
  const illos = [
    <div><Ico d={icons.camera} size={96} stroke={T.brand} sw={1.2}/></div>,
    <div><Ico d={icons.users} size={96} stroke={T.brand} sw={1.2}/></div>,
    <div><Ico d={icons.check} size={96} stroke={T.brand} sw={1.5}/></div>,
  ];
  return (
    <div style={{background:T.canvas, paddingBottom:20}}>
      <ArtboardHeader num="A · Onboarding & Auth" title="First-run journey" subtitle="From cold install to ready-to-track. Social-first auth. Two-step setup. Honest permission asks."/>
      <ScreensGrid>
        <ScreenSplash/>
        <WelcomeSlide idx={0} title="Track spending in seconds." body="Snap a receipt or tap in an amount. We do the math." illustration={illos[0]}/>
        <WelcomeSlide idx={1} title="Share with friends, privately." body="Create a room for trips or the apartment. No one sees the rest." illustration={illos[1]}/>
        <WelcomeSlide idx={2} title="Budgets that make sense." body="Category limits, gentle alerts, real insight." illustration={illos[2]}/>
        <ScreenSignUp/>
        <ScreenSignIn/>
        <ScreenOTP/>
        <ScreenRegion/>
        <ScreenPerms/>
      </ScreensGrid>
    </div>
  );
}

Object.assign(window, {OnboardingArtboard});
