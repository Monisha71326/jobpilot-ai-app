import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'services/api.dart';

const navy = Color(0xFF101B35);
const blue = Color(0xFF5278FF);
const bg = Color(0xFFF4F6FB);

void main() => runApp(const JobPilotApp());

class JobPilotApp extends StatelessWidget {
  const JobPilotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JobPilot', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: blue), appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: navy, elevation: 0), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFFF5F7FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState()=>_AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  bool checking=true, signed=false;
  @override void initState(){super.initState(); _check();}
  Future<void> _check() async { final t=await Api.token(); if(t!=null){try{await Api.request('/me/'); signed=true;}catch(_){await Api.saveToken(null);}} if(mounted)setState(()=>checking=false); }
  @override Widget build(BuildContext context)=>checking?const Scaffold(body:Center(child:CircularProgressIndicator())):signed?const HomeShell():LoginScreen(onLogin:()=>setState(()=>signed=true));
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final server = TextEditingController();
  bool busy = false, register = false, showServer = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadServer();
  }

  Future<void> _loadServer() async {
    server.text = await Api.baseUrl();
    if (mounted) setState(() => showServer = server.text.isEmpty);
  }

  Future<void> submit() async {
    setState(() { busy = true; error = ''; });
    try {
      await Api.saveBaseUrl(server.text);
      if ((await Api.baseUrl()).isEmpty) {
        throw Exception('Enter your hosted JobPilot server URL first.');
      }
      final r = await Api.request(
        register ? '/auth/register/' : '/auth/login/',
        method: 'POST',
        body: {'email': email.text.trim(), 'password': pass.text},
      );
      final t = r['token'] ?? r['key'];
      if (t == null) throw Exception('Authentication token missing');
      await Api.saveToken(t.toString());
      widget.onLogin();
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 76, width: 76,
                  decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 28),
                const Text('Your next career move,\\nstarts here.',
                  style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800, color: navy, height: 1.12)),
                const SizedBox(height: 10),
                const Text('Find opportunities. Build confidence. Get hired.',
                  style: TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.cloud_done_outlined, color: blue),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('JobPilot server', style: TextStyle(fontWeight: FontWeight.w700))),
                      TextButton(
                        onPressed: () => setState(() => showServer = !showServer),
                        child: Text(showServer ? 'Hide' : 'Edit'),
                      ),
                    ]),
                    if (showServer) ...[
                      const Text('Enter the HTTPS URL after your backend is hosted. Do not add /api.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: server,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'https://your-jobpilot-server.com',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    ] else
                      Text(server.text.isEmpty ? 'Server URL not configured' : server.text,
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ]),
                ),
                const SizedBox(height: 24),
                Text(register ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 12),
                TextField(controller: pass, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                if (error.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : submit,
                  style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 17)),
                  child: Text(busy ? 'Please wait…' : register ? 'Create account' : 'Sign in'),
                ),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(register ? 'Already have an account? Sign in' : 'New to JobPilot? Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {const HomeShell({super.key});@override State<HomeShell> createState()=>_HomeShellState();}
class _HomeShellState extends State<HomeShell>{int index=0; final pages=const [DashboardScreen(),JobsScreen(),ApplicationsScreen(),ResumesScreen(),AssistantScreen(),GenericApiScreen(title:'Interview practice',subtitle:'AI-generated interview sessions and answer feedback.',path:'/interviews/'),GenericApiScreen(title:'Skills roadmap',subtitle:'Identify skill gaps and plan your learning journey.',path:'/goals/'),GenericApiScreen(title:'Reminders',subtitle:'Follow-ups and application deadlines.',path:'/reminders/'),GenericApiScreen(title:'Settings & profile',subtitle:'Your account and career profile.',path:'/profile/')]; final titles=['Overview','Find jobs','Applications','My resumes','AI Career Agent','Interview practice','Skills roadmap','Reminders','Settings & profile'];
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Row(children:[Container(width:32,height:32,decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.rocket_launch,color:Colors.white,size:18)),const SizedBox(width:10),Text(titles[index],style:const TextStyle(fontWeight:FontWeight.w800))]),actions:[IconButton(onPressed:()=>showModalBottomSheet(context:context,builder:(_)=>MoreSheet(onSelect:(i){setState(()=>index=i);Navigator.pop(context);})),icon:const Icon(Icons.grid_view_rounded))]),body:IndexedStack(index:index,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:index < 5 ? index : 0,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const [NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),NavigationDestination(icon:Icon(Icons.work_outline),selectedIcon:Icon(Icons.work),label:'Jobs'),NavigationDestination(icon:Icon(Icons.track_changes),label:'Track'),NavigationDestination(icon:Icon(Icons.description_outlined),label:'Resume'),NavigationDestination(icon:Icon(Icons.auto_awesome),label:'AI Agent') ]));}

class MoreSheet extends StatelessWidget {final ValueChanged<int> onSelect;const MoreSheet({super.key,required this.onSelect});@override Widget build(BuildContext context)=>SafeArea(child:Wrap(children:[for(final item in [(5,'Interview practice',Icons.record_voice_over),(6,'Skills roadmap',Icons.school_outlined),(7,'Reminders',Icons.notifications_none),(8,'Settings & profile',Icons.settings_outlined)])ListTile(leading:Icon(item.$3),title:Text(item.$2),onTap:()=>onSelect(item.$1)),ListTile(leading:const Icon(Icons.logout,color:Colors.red),title:const Text('Sign out'),onTap:()async{await Api.saveToken(null);if(context.mounted)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>AuthGate()),(_)=>false);})]));}

class PageFrame extends StatelessWidget {final String title,subtitle;final Widget child;const PageFrame({super.key,required this.title,required this.subtitle,required this.child});@override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()=>Future.delayed(const Duration(milliseconds:500)),child:ListView(padding:const EdgeInsets.fromLTRB(18,8,18,28),children:[Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Colors.blueGrey)),const SizedBox(height:20),child]));}
Widget stat(String label,String value,IconData icon,Color color)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color),const SizedBox(height:12),Text(value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,color:navy)),Text(label,style:const TextStyle(fontSize:12,color:Colors.blueGrey))]))));
Widget panel(String title,Widget child)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:navy)),const SizedBox(height:14),child])));

class DashboardScreen extends StatefulWidget{const DashboardScreen({super.key});@override State<DashboardScreen> createState()=>_DashboardScreenState();}
class _DashboardScreenState extends State<DashboardScreen>{Map<String,dynamic>? data;String error='';@override void initState(){super.initState();load();}Future<void> load()async{try{final r=await Api.request('/dashboard/');if(mounted)setState(()=>data=Map<String,dynamic>.from(r));}catch(e){if(mounted)setState(()=>error=e.toString());}}
 @override Widget build(BuildContext context)=>PageFrame(title:'Good to see you 👋',subtitle:'Your career progress, all in one place.',child:data==null?Center(child:Padding(padding:const EdgeInsets.all(35),child:error.isNotEmpty?Text(error):const CircularProgressIndicator())):Column(children:[Row(children:[stat('Applications','${data!['total_applications']??0}',Icons.send_rounded,blue),const SizedBox(width:10),stat('Saved jobs','${data!['saved_jobs']??0}',Icons.bookmark_outline,Colors.orange)]),Row(children:[stat('Response rate','${data!['response_rate']??'—'}%',Icons.trending_up,Colors.green),const SizedBox(width:10),stat('Profile','${data!['profile_completeness']?['percent']??0}%',Icons.person_outline,Colors.purple)]),panel('Application pipeline',Column(children:[for(final s in ['wishlist','preparing','applied','interviewing','offer','rejected'])ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(s[0].toUpperCase()+s.substring(1)),trailing:Text('${data!['counts']?[s]??0}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))) ])),panel('AI readiness',Row(children:[Icon(data!['ai']?['ready']==true?Icons.check_circle:Icons.info_outline,color:data!['ai']?['ready']==true?Colors.green:Colors.orange),const SizedBox(width:10),Expanded(child:Text(data!['ai']?['ready']==true?'Your local AI assistant is ready':'Rules-based assistance is available. Configure Ollama on your backend for local LLM responses.'))]))]));}

class JobsScreen extends StatefulWidget{const JobsScreen({super.key});@override State<JobsScreen> createState()=>_JobsScreenState();}
class _JobsScreenState extends State<JobsScreen>{List items=[];bool loading=true;String q='';@override void initState(){super.initState();load();}Future<void>load()async{setState(()=>loading=true);try{final r=await Api.request('/jobs/',query:{'search':q});items=(r['results']??[]) as List;}catch(e){_snack(context,e.toString());}if(mounted)setState(()=>loading=false);}
 @override Widget build(BuildContext context)=>PageFrame(title:'Discover your next role',subtitle:'Relevant opportunities with explainable match scores.',child:Column(children:[TextField(onSubmitted:(v){q=v;load();},decoration:InputDecoration(hintText:'Search title, company or skills',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(icon:const Icon(Icons.tune),onPressed:load))),const SizedBox(height:14),if(loading)const CircularProgressIndicator() else if(items.isEmpty)const Text('No jobs found. Try another search or refresh job sources.') else for(final j in items)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${j['title']}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))),if(j['match_score']!=null)Text('${j['match_score']}% match',style:const TextStyle(color:blue,fontWeight:FontWeight.bold))]),Text('${j['company']} · ${j['location']??'Location not listed'}',style:const TextStyle(color:Colors.blueGrey)),const SizedBox(height:10),Text((j['snippet']??'').toString(),maxLines:3,overflow:TextOverflow.ellipsis),const SizedBox(height:8),Wrap(spacing:8,children:[OutlinedButton.icon(onPressed:()async{try{if(j['is_saved']==true){await Api.request('/saved-jobs/${j['id']}/',method:'DELETE');}else{await Api.request('/saved-jobs/',method:'POST',body:{'job_id':j['id']});}load();}catch(e){_snack(context,e.toString());}},icon:const Icon(Icons.bookmark_border),label:Text(j['is_saved']==true?'Saved':'Save')),FilledButton.tonal(onPressed:()async{try{await Api.request('/applications/',method:'POST',body:{'job_id':j['id']});_snack(context,'Added to your application tracker');}catch(e){_snack(context,e.toString());}},child:const Text('Track job'))])]))]));}

class ApplicationsScreen extends StatefulWidget{const ApplicationsScreen({super.key});@override State<ApplicationsScreen> createState()=>_ApplicationsScreenState();}
class _ApplicationsScreenState extends State<ApplicationsScreen>{List rows=[];String filter='all';@override void initState(){super.initState();load();}Future<void>load()async{try{final r=await Api.request('/applications/');if(mounted)setState(()=>rows=(r['results']??[]) as List);}catch(e){_snack(context,e.toString());}}
 @override Widget build(BuildContext context){final shown=filter=='all'?rows:rows.where((x)=>x['status']==filter).toList();return PageFrame(title:'Your application tracker',subtitle:'Keep every opportunity moving forward.',child:Column(children:[DropdownButtonFormField<String>(value:filter,decoration:const InputDecoration(labelText:'Filter status'),items:['all','wishlist','preparing','applied','interviewing','offer','rejected','withdrawn'].map((s)=>DropdownMenuItem(value:s,child:Text(s.toUpperCase()))).toList(),onChanged:(v)=>setState(()=>filter=v??'all')),const SizedBox(height:12),if(shown.isEmpty)const Text('No applications yet. Track a job to see it here.'),for(final a in shown)Card(child:ListTile(title:Text('${a['job_title']}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${a['company']} · ${a['status']}'),trailing:PopupMenuButton<String>(onSelected:(s)async{try{var confirm=false;if(s=='applied'){confirm=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Confirm application submitted'),content:const Text('Only continue if you have actually submitted this application on the employer website.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Not yet')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Yes, submitted'))]))??false;if(!confirm)return;}await Api.request('/applications/${a['id']}/move/',method:'POST',body:{'status':s,'confirm_submitted':confirm});load();}catch(e){_snack(context,e.toString());}},itemBuilder:(_)=>['wishlist','preparing','applied','interviewing','offer','rejected','withdrawn'].map((s)=>PopupMenuItem(value:s,child:Text(s))).toList(),child:const Icon(Icons.more_vert))))]));}}

class ResumesScreen extends StatefulWidget{const ResumesScreen({super.key});@override State<ResumesScreen> createState()=>_ResumesScreenState();}
class _ResumesScreenState extends State<ResumesScreen>{List rows=[];@override void initState(){super.initState();load();}Future<void>load()async{try{final r=await Api.request('/resumes/');if(mounted)setState(()=>rows=r);}catch(e){_snack(context,e.toString());}}
 Future<void>pick()async{final f=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['pdf','docx'],withData:false);if(f==null)return;try{await Api.upload('/resumes/',f.files.single.path!,f.files.single.name);load();_snack(context,'Resume uploaded and parsed');}catch(e){_snack(context,e.toString());}}
 @override Widget build(BuildContext context)=>PageFrame(title:'Build a stronger resume',subtitle:'Upload a PDF or DOCX and get ATS analysis.',child:Column(children:[FilledButton.icon(onPressed:pick,icon:const Icon(Icons.upload_file),label:const Text('Upload resume')),const SizedBox(height:14),if(rows.isEmpty)const Text('No resume uploaded yet.'),for(final r in rows)Card(child:ListTile(leading:const Icon(Icons.description,color:blue,size:32),title:Text('${r['title']}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${r['skills']?.length??0} skills · ${r['is_primary']==true?'Primary resume':'Resume'}'),trailing:PopupMenuButton<String>(onSelected:(s)async{try{await Api.request('/resumes/${r['id']}/$s/',method:'POST');load();}catch(e){_snack(context,e.toString());}},itemBuilder:(_)=>const [PopupMenuItem(value:'analyze',child:Text('Analyse resume')),PopupMenuItem(value:'set-primary',child:Text('Set as primary'))])))]));}

class AssistantScreen extends StatefulWidget{const AssistantScreen({super.key});@override State<AssistantScreen> createState()=>_AssistantScreenState();}
class _AssistantScreenState extends State<AssistantScreen>{final input=TextEditingController();final scroll=ScrollController();List<Map<String,dynamic>> messages=[];int? conversation;bool sending=false;@override void initState(){super.initState();createConversation();}Future<void>createConversation()async{try{final r=await Api.request('/assistant/conversations/',method:'POST',body:{'title':'Mobile AI Career Coach'});conversation=r['id'];}catch(e){_snack(context,e.toString());}}
 Future<void>send([String? suggested])async{final text=(suggested??input.text).trim();if(text.isEmpty||sending)return;if(conversation==null)await createConversation();if(conversation==null)return;input.clear();setState((){sending=true;messages.add({'role':'user','content':text});});try{final r=await Api.request('/assistant/conversations/$conversation/messages/',method:'POST',body:{'content':text});setState(()=>messages.add(Map<String,dynamic>.from(r['assistant_message'])));}catch(e){setState(()=>messages.add({'role':'assistant','content':'I could not reach the AI service: $e'}));}finally{setState(()=>sending=false);}}
 @override Widget build(BuildContext context)=>Column(children:[Expanded(child:ListView(controller:scroll,padding:const EdgeInsets.all(16),children:[if(messages.isEmpty)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.auto_awesome,color:Color(0xFF9DB1FF),size:30),SizedBox(height:12),Text('Meet your AI Career Agent',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('Ask me to improve your resume, prepare for interviews, plan skills or make your job search smarter.',style:TextStyle(color:Colors.white70))])),if(messages.isEmpty)...['Review my resume and suggest improvements','Prepare me for a software developer interview','Create a 30-day job search plan'].map((s)=>Padding(padding:const EdgeInsets.only(top:10),child:ActionChip(avatar:const Icon(Icons.bolt,size:16),label:Text(s),onPressed:()=>send(s)))),for(final m in messages)Align(alignment:m['role']=='user'?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.symmetric(vertical:6),padding:const EdgeInsets.all(14),constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.84),decoration:BoxDecoration(color:m['role']=='user'?navy:Colors.white,borderRadius:BorderRadius.circular(18)),child:m['role']=='user'?Text('${m['content']}',style:const TextStyle(color:Colors.white)):MarkdownBody(data:'${m['content']}',styleSheet:MarkdownStyleSheet(p:const TextStyle(color:navy))))),if(sending)const Align(alignment:Alignment.centerLeft,child:Padding(padding:EdgeInsets.all(12),child:CircularProgressIndicator()))])),SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Row(children:[Expanded(child:TextField(controller:input,minLines:1,maxLines:4,onSubmitted:(_)=>send(),decoration:InputDecoration(hintText:'Ask your career agent…',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:13)))),const SizedBox(width:8),IconButton.filled(onPressed:sending?null:()=>send(),icon:const Icon(Icons.arrow_upward),style:IconButton.styleFrom(backgroundColor:navy,foregroundColor:Colors.white))])))]);}

class GenericApiScreen extends StatefulWidget {
  final String title, subtitle, path;
  const GenericApiScreen({super.key, required this.title, required this.subtitle, required this.path});
  @override
  State<GenericApiScreen> createState() => _GenericApiScreenState();
}

class _GenericApiScreenState extends State<GenericApiScreen> {
  dynamic data;
  String error = '';
  bool loading = true, busy = false;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = ''; });
    try {
      final r = await Api.request(widget.path);
      if (mounted) setState(() { data = r; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> createItem() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.path == '/interviews/' ? 'Start a mock interview' :
          widget.path == '/goals/' ? 'Create career goal' : 'Add reminder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.path == '/interviews/' ? 'Target role' :
              widget.path == '/goals/' ? 'Career target role' : 'Reminder title',
            hintText: widget.path == '/interviews/' ? 'e.g. Flutter Developer' :
              widget.path == '/goals/' ? 'e.g. Backend Engineer' : 'e.g. Follow up with recruiter',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;

    setState(() => busy = true);
    try {
      if (widget.path == '/interviews/') {
        final r = await Api.request('/interviews/', method: 'POST',
          body: {'role': value, 'kind': 'mixed', 'count': 5});
        await load();
        if (mounted) await openInterview(Map<String, dynamic>.from(r));
      } else if (widget.path == '/goals/') {
        await Api.request('/goals/', method: 'POST', body: {'target_role': value});
        await load();
      } else if (widget.path == '/reminders/') {
        await Api.request('/reminders/', method: 'POST', body: {
          'title': value,
          'due_at': DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(),
        });
        await load();
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openInterview(Map<String, dynamic> session) async {
    final id = session['id'];
    if (id == null) return;
    try {
      final detail = Map<String, dynamic>.from(await Api.request('/interviews/$id/'));
      final questions = (detail['questions'] as List? ?? []);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${detail['role_title'] ?? 'Interview'} practice'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${detail['answered'] ?? 0} of ${detail['total'] ?? questions.length} answered',
                    style: const TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  for (final q in questions)
                    Card(
                      child: ListTile(
                        title: Text('${q['question'] ?? q['text'] ?? q}'),
                        subtitle: const Text('Tap to write your answer and receive AI feedback'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final answer = TextEditingController();
                          final response = await showDialog<String>(
                            context: ctx,
                            builder: (aCtx) => AlertDialog(
                              title: const Text('Your answer'),
                              content: TextField(controller: answer, minLines: 4, maxLines: 8,
                                decoration: const InputDecoration(hintText: 'Write your answer using Situation, Task, Action, Result…')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(aCtx), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(aCtx, answer.text.trim()), child: const Text('Evaluate')),
                              ],
                            ),
                          );
                          answer.dispose();
                          if (response == null || response.length < 3) return;
                          try {
                            final ev = await Api.request('/interviews/$id/answer/', method: 'POST',
                              body: {'question_index': q['id'], 'answer': response});
                            if (ctx.mounted) _snack(ctx, 'Answer evaluated: ${ev['evaluation']?['score'] ?? 'Feedback ready'}');
                          } catch (e) {
                            if (ctx.mounted) _snack(ctx, e.toString());
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
      await load();
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    }
  }

  Future<void> completeReminder(Map<String, dynamic> item) async {
    try {
      await Api.request('/reminders/${item['id']}/', method: 'PATCH', body: {'done': true});
      await load();
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    }
  }

  Widget _record(Map<String, dynamic> item) {
    if (widget.path == '/interviews/') {
      return Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.record_voice_over)),
        title: Text('${item['role_title'] ?? 'Interview practice'}'),
        subtitle: Text('${item['kind'] ?? 'mixed'} · ${item['answered'] ?? 0}/${item['total'] ?? 0} answered · ${item['status'] ?? ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openInterview(item),
      ));
    }
    if (widget.path == '/goals/') {
      final progress = (item['progress'] is num ? item['progress'] as num : 0).toDouble();
      return Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item['title'] ?? item['target_role'] ?? 'Career goal'}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 5),
          Text('Target: ${item['target_role'] ?? ''}', style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: (progress / 100).clamp(0, 1)),
          const SizedBox(height: 6),
          Text('${progress.round()}% progress'),
        ]),
      ));
    }
    if (widget.path == '/reminders/') {
      final done = item['done'] == true;
      return Card(child: ListTile(
        leading: Icon(done ? Icons.check_circle : Icons.notifications_active_outlined,
          color: done ? Colors.green : blue),
        title: Text('${item['title'] ?? 'Reminder'}'),
        subtitle: Text('${item['due_at'] ?? ''}'),
        trailing: done ? const Icon(Icons.check) : IconButton(
          icon: const Icon(Icons.done_all),
          onPressed: () => completeReminder(item),
        ),
      ));
    }
    return Card(child: ListTile(
      title: Text('${item['title'] ?? item['name'] ?? 'Record'}'),
      subtitle: Text(item.entries.map((e) => '${e.key}: ${e.value}').take(3).join(' · ')),
    ));
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: widget.title,
    subtitle: widget.subtitle,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.path != '/profile/')
        FilledButton.icon(
          onPressed: busy ? null : createItem,
          icon: const Icon(Icons.add),
          label: Text(widget.path == '/interviews/' ? 'Start interview' :
            widget.path == '/goals/' ? 'Create career goal' : 'Add reminder'),
          style: FilledButton.styleFrom(backgroundColor: navy),
        ),
      const SizedBox(height: 12),
      if (loading) const Center(child: Padding(
        padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
      if (!loading && error.isNotEmpty) panel('Could not load data', Column(children: [
        Text(error), TextButton(onPressed: load, child: const Text('Try again')),
      ])),
      if (!loading && data is List && (data as List).isEmpty)
        panel('Nothing here yet', const Text('Create your first item to get started.')),
      if (!loading && data is List)
        for (final raw in data as List)
          if (raw is Map) _record(Map<String, dynamic>.from(raw)),
      if (!loading && data is Map)
        panel('Your profile', Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: (data as Map).entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text('${e.key.replaceAll('_', ' ')}: ${e.value}'),
          )).toList())),
    ]),
  );
}

void _snack(BuildContext c,String s){ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s.replaceFirst('Exception: ',''))));}
