
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.14,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

