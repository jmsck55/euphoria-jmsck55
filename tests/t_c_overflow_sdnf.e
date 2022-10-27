include std/unittest.e

-- highest double atom is
atom h = 179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
-- this is 1/2^50 % bigger than the biggest number with a fraction part.  Other numbers might get rounded down to h.
atom a = 1189731495357231765061573524029118283665551675295802973585543163480189725933916325296459231046580856017026785105835409779721333295944287804245875026658632008303142221743868034652058001618317725915793782560972992384764826152583032555032476149863733986228310248957349418500837539512705674127319556174981362236328931656848225436384089331634371086908266190812872504677475252771355283238041345113645268015010114277595704115875432937035775829344321741904637829613005874302141936139913320890784339508611093729723032457171430278773518501138539949283835850381031728286234031292950528894636157435539869205894864947910491282480301974056514282193290943682726740839066351463661466000666781859699506570201863590631538979508617843584866756934499904454006639406992067889461290837970377644443955039975116132355541011608284084797487135543370843405002007793701061972624619877879857631943115913935124609219431004947304838526861033317081579357865571932110646565368076611710406627062267340013616385912946055211011711046530554912994275262687379913424680037891487739699517306117815157253092699943345407098026139959175988276265692617187797496131584754621076190489057112565283736191732524784885568669568432780567567736368432085194645132286280206055100601984271435284106134546402668682872959945479907915616907782279909548198039703259493991598542818912759827350031599090694028819169096371684922033439503403110199745624614677993106323811144410515744663492848326477434602632072106297002328547987676136447241374959099768065866348983768965912667526840991317618816931068314512444338672342216119956583226813600983170152511337173538346541758117803375138811474767765598746995762506338998121213171447196810467095187570956600155697417243521774729526798459107223501855589229579047190073389039552760600664068568013996436353604935565828171272330844129560239175576014038422249987821037063017413594553811139524014357571072302225680436075177098739862721927293489817517618028636755340670857390239727300632849285982050630745041023600515741750334317575980976280731887226058252212051236564016597931907097082652855872683582328396782260407317258221965679437095505258620618389218675036678796699933453031433747782288302223402385020706252430292555607695078149285325611141093233119928967723254260738939586423084320316496068539832013274904130966989354851756164785439214248604551140604343010187941299566543347709869877333437526730686654838579643284937406212992356153342508574979785355393167392615270439555358588356611306624520121866665731759637096602473764329001821409056642079762736235772844656280134064046813950815649432247988877328095840844816672117922556671652052332574495281394195204338945751366326426865860724342503576931877906871520176851550725276923730209566357851179917075647876975875355975408180779015365168873358415011461108940019676707663771669575817430642721773680933170924873517285026587757277409827083772279159260975945895545387185112930999098371785602331842213128798021308696040586211283983666214827469339851166728113910601309372887852124550536176525071495831460138799139749034848857776303525400453874701311861180986731084550613880156161236858342557664390289681541775771915205134300893108576653742761010180561191979124080410671193523944705692852235379834983252160447640393134960759330379136723907258465072713704638607982135040977651794982232318725407344108374255244941080997331422678475206109439658900338681582401780628088094680620445821204075653349136438510206700563608546871673516272697670459167445733833726875060036080526431727185640538282571734344980949258226910291455050852304989496453153340699619860889208919894538790871210074800328291819337231875173989177766448706216853475103593845483512527807133274656799410803907669763719959372042057835936747143442533196691357056497056187748819759975693415499718141635498560397335241754823150372427099729621703491649792971866687245063663037603153478954484884798711191728356774821107670970597175991679794428893073291950385382992021712178173213378540697046397626549374544932271599892812797833932967592572642053996303738491869986602694697529964193492752365487243492100364176187780848123728619608682359541591986192656502390246877179151014922568822601848604902470449071730983422425508608614891734781869963289753970346687295443131209722985291963712269553251592083839205320550372893678380623368860606384852788434220294129692902656759492708204686605849175320066498703952183123683945250232528097600639475773340604762037449921141137606671568680367792941557311371056123645627267552696303152706893107045354008962770274311644615920054620567087179560362093775603551287509068602353297812675390679046185535231508723786983158576370530644458195892110388485037088802754735645272455201887738280937784999977721809259849423725393821125704445597429633246332723130225848883531994584559198791488370168919322322233904960653690590908097327037649282522971083373008221290780563839829789453731901245490069297263444218750618254479631029014436724089223223705600.477
test_pass("Huge standard decimal floating point notation number")
test_report()