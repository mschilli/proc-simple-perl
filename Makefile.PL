
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.16,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

