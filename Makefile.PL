
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.12,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

