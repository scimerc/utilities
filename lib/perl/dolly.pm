package Job;

my $PENDING  = 'P';
my $RUNNING  = 'R';
my $ERROR    = 'E';
my $FINISHED = 'F';

use overload '""' => 'stringify';

sub new
{
 my $class = shift;
 my %args  = 
 (
  -name => 'noname',
  -command => '',
  -workDir => '',
  -homeDir => '',
  -consumedFiles => [],
  -producedFiles => [],
  -cleanUp => 1,
  -qsubCliArguments => '',
  -maxRetriesOnError => 0,
  -wake_up_every => 5, # time to sleep before retrying openReadWait
  -timeout => 60, # max. number of seconds waited for Job results being copied
  @_
 );
 
 die "Dolly::Job->new: Working directory should be local" if( $args{-workDir} =~ /scratch\/scratch/ );
 
 my $self = 
 {
  'name' => $args{-name},
  'pid' => -1,
  'status' => $PENDING,
  'homeDir' => $args{-homeDir},
  'workDir' => $args{-workDir},
  'commandLine' => $args{-command},
  'cfiles' => $args{-consumedFiles},
  'pfiles' => $args{-producedFiles},
  'maxRetries' => $args{-maxRetriesOnError},
  'doCleanUp' => $args{-cleanUp},
  'qsubArgs' => $args{-qsubCliArguments},
  # private variables
  'retries' => 0,
  'timeout' => $args{-timeout},
  'sleep' =>  $args{-wake_up_every}
 };
 
 bless $self, $class;
}

sub name
{
 $_[0]->{'name'};
}

sub homeDir
{
 $_[0]->{'homeDir'};
}

sub workDir
{
 $_[0]->{'workDir'};
}

sub action
{
 $_[0]->{'commandLine'};
}

sub consumedFiles
{
 @{$_[0]->{'cfiles'}};
}

sub producedFiles
{
 @{$_[0]->{'pfiles'}};
}

sub status : lvalue
{
 $_[0]->{'status'};
}

sub run
{
 $_[0]->status = $RUNNING;
}

sub retry
{
 return (++$_[0]->{'retries'} < $_[0]->{'maxRetries'});
}

sub finish
{
 $_[0]->status = $FINISHED;
 
 return $_[0]->status;
}

sub error
{
 $_[0]->status eq $ERROR;
}

sub pid : lvalue
{
 $_[0]->{'pid'};
}

sub qsubCliArguments
{
 $_[0]->{'qsubArgs'};
}

sub batchScript
{
 my $self  = shift;
 my $batch = '';

 # shebang
 $batch .= sprintf("#!/bin/csh\n");

 # copy files
 $batch .= sprintf("mkdir -p %s\n", $self->workDir);
 foreach my $file ( $self->consumedFiles )
 {
  $batch .= sprintf("cp %s/%s %s\n", $self->homeDir, $file, $self->workDir);
 }
 
 # run
 $batch .= sprintf("cd %s\n%s\n", $self->workDir, $self->action);
 
 # copy results
 foreach my $file ( $self->producedFiles )
 {
  $batch .= sprintf("cp %s/%s %s\n", $self->workDir, $file, $self->homeDir);
 }

 # clean up
 $batch .= sprintf("cd %s\nrm -r %s\n", $self->homeDir, $self->workDir) if( $self->{'doCleanUp'} );
 
 return $batch;
}

sub openReadWait
{
 my ($self, $file) = @_;

 $awhile  = $self->{'sleep'};
 $maxwait = $self->{'timeout'};

 # try to open file
 my $time    = 0;
 my $success = undef;
 while( $time<$maxwait )
 {
  $success = open(IN, "< $file");
  last if($success);
  sleep $awhile;
  $time += $awhile;
 }
 
 # return file handle
 if($success)
 {
  return *IN;
 }
 else
 {
  return undef;
 }
}

sub waitForProducedFiles
{
 my $self = shift;
 foreach my $file ( $self->producedFiles )
 {
  my $fh = $self->openReadWait($file) or die "Dolly::Job->waitForProducedFiles: Timeout while waiting for produced file $file in job: $self";
  close $fh;
 }
}

sub readStdErr
{
 my ($self, $dir) = (shift, shift);

 my $name   = $self->name;
 my $pid    = $self->pid;
 my $stderr = "$dir/$name.e$pid";
 my $fh     = $self->openReadWait($stderr) or die "Dolly::Job->readStdErr: Time out while opening $stderr";
 
 # parse STDERR
 my @lines;
 while(my $line = <$fh>) 
 { 
  push @lines, $line 
 }
 close $fh;
 
 $self->status = $ERROR if(@lines);

 return @lines;
}

sub readStdOut
{
 my ($self, $dir) = @_[0..1];

 my $name   = $self->name;
 my $pid    = $self->pid;
 my $stdout = "$dir/$name.o$pid";
 my $fh     = $self->openReadWait($stdout, @_) or die "Dolly::Job->readStdOut: Time out while opening $stdout";
 
 # parse STDERR
 my @lines;
 while(my $line = <$fh>) 
 { 
  push @lines, $line 
 }
 close $fh;
 
 return @lines;
}

sub stringify
{
 my $self = shift;

 sprintf("%i %s (%s)", $self->pid, $self->name, $self->status);
}

package Queue;

use overload '""' => 'stringify';

sub new
{
 my $class = shift;
 my %args = 
 (
  -limit=>999,
  @_
 );
 
 my $self  = {'@objs'=>[], 'limit'=>$args{-limit}};
 
 bless $self, $class;
}

sub enqueue
{
 my ($self, $obj) = @_;
 
 if($self->full)
 {
  return undef;
 }
 else
 {
  push @{$self->{'@objs'}}, $obj;
  return 1;
 }
}

sub peek
{
 my ($self, $idx) = @_;
 my $obj = $self->{'@objs'}->[$idx] or die "Dolly::Queue->peek: Element $idx does not exist";
 
 return $obj;
}

sub drop
{
 my ($self, $idx) = @_;
 my $obj = $self->{'@objs'}->[$idx] or die "Dolly::Queue->drop: Element $idx does not exist";

 for(my $i=$idx; $i<@{$self->{'@objs'}}-1; $i++)
 {
  $self->{'@objs'}->[$i] = $self->{'@objs'}->[$i+1];
 }
 $#{$self->{'@objs'}}--;
 
 return $obj;
}

sub dequeue
{
 shift @{$_[0]->{'@objs'}};
}

sub size
{
 scalar @{$_[0]->{'@objs'}};
}

sub empty
{
 @{$_[0]->{'@objs'}}==0?1:0;
}

sub full
{
 @{$_[0]->{'@objs'}}>=$_[0]->{'limit'}?1:0;
}

sub stringify
{
 my $self = shift;

 my $cnt = 0;
 my $str = '';
 foreach my $obj ( @{$self->{'@objs'}} )
 {
  $str .= sprintf("%i. %s\n", ++$cnt, $obj);
 }
 
 return $str;
}

package Controller;

use overload '""' => 'stringify';

sub new
{
 my $class = shift;
 my %args = 
 (
  -dollyDir => undef,
  -maxRunningJobs => 5,
  -qstat => 'qstat',
  -qsub => 'qsub',
  -wake_up_every => 20, # seconds
  @_
 );
 
 my ($username) = getpwuid($<);
 
 my $self = 
 {
  # private variables
  'pending'  => Queue->new,
  'running'  => Queue->new(-limit=>$args{-maxRunningJobs}),
  'finished' => Queue->new,
  'base' => defined($args{-dollyDir})?$args{-dollyDir}:"/scratch/scratch/$username",
  'qstat' => $args{-qstat},
  'qsub' => $args{-qsub},
  'username' => $username,
  'options' => \%args
 };
 
 bless $self, $class;
}

sub addJob
{
 my $self = shift;
 
 foreach my $job (@_)
 {
  $self->{'pending'}->enqueue($job);
 }
}

sub run
{
 my $self     = shift;
 my $callback = shift;
 
 my $opt     = $self->{'options'};
 my $awhile  = $opt->{-wake_up_every};

 # queues
 my $pqueue = $self->{'pending'};
 my $rqueue = $self->{'running'};

 # run!
 my $time = time;
 $self->process;
 &$callback($self) if($callback);
 while( !$pqueue->empty || !$rqueue->empty )
 {
  sleep $awhile;
  $self->process;
  &$callback($self) if($callback);
 }
 
 return time-$time;
}

sub process
{
 my $self = shift;
 
 #queues
 my $pqueue = $self->{'pending'};
 my $rqueue = $self->{'running'};
 my $fqueue = $self->{'finished'};
 my $errorFlag = 0;
 
 # parse options
 my $opt = $self->{'options'};
 
 # synchronize with qstat
 my %qstat = $self->qstat;
 for(my $i=0; $i<$rqueue->size; $i++)
 {
  my $job = $rqueue->peek($i);
  my $pid = $job->pid;
  unless( exists($qstat{$pid}) ) # pid not listed by qstat anymore
  {
   $rqueue->drop($i);
   $job->readStdErr($self->{'base'});
	if($job->error)
	{
	 if($job->retry)
	 {
     $pqueue->enqueue($job);
	 }
	 else
	 {
	  warn "Dolly::Controller->process: Job $job produced an error\n";
	  $errorFlag = 1;
	 }
	}
   #$job->waitForProducedFiles;
   $job->finish;
   $fqueue->enqueue($job);
  }
 }
 #die "Dolly::Controller->process: Dying because a job produced an error." if($errorFlag);
 
 # fill running queue
 while( !$pqueue->empty && !$rqueue->full )
 {
  my $temp = $pqueue->dequeue;
  $self->qsub($temp);
  $temp->run;
  $rqueue->enqueue($temp);
 }
}

sub qstat
{
 my $self = shift;
 
 my $qstat = $self->{'qstat'};
 my $username = $self->{'username'};
 my %jobs;

 open(QSTAT, "$qstat |") or die "Dolly::Controller->qstat: Could not run qstat";
 foreach my $line (<QSTAT>)
 {
  if($line =~ /$username/)
  {
   my @data = split(' ', $line);
	my $pid = $data[0];
	my $jobname = $data[2];
	$jobs{$pid} = $jobname;
  }
 }
 close QSTAT;
 
 return %jobs;
}

sub qsub
{
 my ($self, $job, $cliparms) = @_;

 my $qsub   = $self->{'qsub'}; 

 # batch script
 my $script = $job->batchScript;
 my $name   = $job->name;
 open(TMP, "> $name") or die "Dolly::Controller->qsub: Could not write batch script $name";
  print TMP $script;
 close TMP;
 
 # run qsub
 $cliparms = $job->qsubCliArguments unless($cliparms);
 open(QSUB, "$qsub $cliparms $name |") or die "Dolly::Controller->qsub: Could not run $qsub $cliparms $name";
  my $retStr = <QSUB>;
  die "Dolly::Controller->qsub: Error in $qsub $cliparms $name -- check STDERR" unless( defined($retStr) );
  my @temp   = split(' ', $retStr);
  $job->pid = $temp[2];
 close QSUB;
 
 # clean up
 system("rm $name");
}

sub stringify
{
 my $self = shift;
 my $str = '';
 
 my $pqueue = $self->{'pending'};
 my $rqueue = $self->{'running'};
 my $fqueue = $self->{'finished'};

 # print queues
 $str .= sprintf "+---------------------------- Pending jobs : ----------------------------------+\n";
 $str .= sprintf "%s", $pqueue;
 $str .= sprintf "+---------------------------- Running jobs : ----------------------------------+\n";
 $str .= sprintf "%s", $rqueue;
 $str .= sprintf "+--------------------------- Finished jobs : ----------------------------------+\n";
 $str .= sprintf "%s", $fqueue;
 $str .= sprintf "+------------------------------------------------------------------------------+\n";
}

1;

__END__

=head1 NAME

Dolly - Perl interface to Dolly-Queuing system

=head1 SYNOPSIS

#!/usr/bin/perl -w

use Dolly;

my @ns = (30, 40, 35, 30, 25, 20);
@ns = (@ns, @ns, @ns);

my $control = Controller->new(-maxRunningJobs=>6); 
my $cnt = 0;
foreach my $n (@ns)
{
 $cnt++;
 $control->addJob
 (
  Job->new
  (
   -name=>"fib-$n-$cnt", 
	-homeDir=>"/scratch/scratch/gernotf/dolly_test", 
	-workDir=>"/public/scratch/gernotf/fib-$n-$cnt", 
	-command=>"./test.pl $n", 
	-consumedFiles=>['test.pl'], 
	-qsubCliArguments=>'-hard -q dollyD15.q,dollyD16.q,dollyD17.q'
  ) 
 ); 
}

my $time_elapsed = $control->run( sub {print "$_[0]\n"} );

printf "Script terminated normally after %i seconds.\n", $time_elapsed;

exit;

=head1 DESCRIPTION

This package provides a simple object-oriented Perl interface to the Grid Engine software used for our Dolly cluster. Useful if you want to submit jobs automatically from a workstation.

=head1 Public class interface

=head2 Job

The elementary class describing a job to be processed on the Dolly cluster.

=head3 Public methods

=head4 new(%hash)

Constructor, returns a new instance of the Class job. All parameters are passed as hash and described by the following keywords:

=over 2

=item '-name' => $string, the jobname also used for temporary file/directory names, expected to be unique.

=item '-workDir' => $string, the local working directory on a Dolly node.

=item '-homeDir' => $string, the remote home directory from which batch job is copied. Must be accessible from dolly node. Currently should be resting somewhere down in '/scratch/scratch'.

=item '-consumedFiles' => ['file1', 'file2', ...], list of files needed for a successful batch job run. Will be copied from -homedir into -workDir.

=item '-producedFiles' => ['file1', 'file2', ...], list of files produced during batch job run. Will be copied from -workDir to -homeDir.

=item '-command' => $string, the command line representing the main program to be started on dolly node.

=item '-qsubCliArguments' => $string, command line arguments passed to 'qsub'. Useful to specify queues manually or optional ressources.

=item '-cleanUp' => 0/1 (default: 1), flag to specify whether -workDir should be removed from dolly node again after batch job has stopped running and -producedFiles were copied to -homeDir.

=item '-maxRetriesOnError' => $int (default: 0), number of retries for the job before being removed. After a job finished the STDERR is parsed to check whether it produced some errors. If errors were found, the job will be re-scheduled up to -maxRetriesOnError times.

=item '-timeout' => $int (default: 60), maximum number of seconds that are waited for job files being copied after finishing.

=item '-wake_up_every' => $int (default: 5), check every X seconds whether files were copied (relevent for waitForProducedFiles)

=back

=head4 status : lvalue

Set or get current status of job: 'P' - pending, 'R' - running, 'E' - error, 'F' - finished.

=head4 run

Switch to status to 'R' - running. Called by Controller when the job is submitted to dolly. Overload to trigger events in your main program.

=head4 finish

Switch to status to 'F' - finished. Called by Controller when the job is finished. Overload to trigger events in your main program.

=head4 error

Returns true when job is in error state.

=head4 @array = readStdErr($directory)

Parse STDERR stream produced by the job and stored in a file located in $directory by Sun Grid Engine.

=head4 @array = readStdOut($directory)

Parse STDOUT stream produced by the job and stored in a file located in $directory by Sun Grid Engine.

=head4 @array = producedFiles

Returns the list of file names which are to be produced by the job.

=head4 waitForProducedFiles

Wait until all produced are copied and can be accessed.

=head4 stringify

Overloads stringify-operator to produce a string representation of the job in string context. The string has the form '%PID %NAME (%STATUS)'.

=head2 Controller

The Controller will manage your jobs. It deploys three queuing objects, each storing pending, running and finished jobs, respectively. The controller will wake up after a user-specified time interval and check for the status of the jobs on Dolly. It basically interfaces 'qsub' and 'qstat'.

=head3 Public methods

=head4 new(%hash)

The constructor. Accepts the following parameters:

=over 2

=item '-maxRunningJobs' => $int (default: 5), number of jobs allowed to run at the same time.

=item '-wake_up_every' => $int (default: 20 seconds), number of seconds to sleep.

=item '-qstat' => $string, path to qstat executable.

=item '-qsub' => $string, path to qsub executable.

=item '-dollyDir' => $string (default: '/scratch/scratch/yourusername'), path to Dolly home directory (the location of STDERR or STDOUT directory).

=back

=head4 addJob($job)

Add a job the pending queue.

=head4 run($callback)

Start the job processing. Returns the number of seconds until completion of all jobs in the pending queue. You can optionally pass a callback which will be called after every wake-up and passed a reference of the controller object. The callback could print the queue status or trigger events in your main program.

=head4 stringify

Returns a string representation of the controller object.

=head1 AUTHORS

(c) Gernot Kieseritzky in 2006. Email: gernotk@gmail.com

=cut
