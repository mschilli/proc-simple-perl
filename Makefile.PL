
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.13,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

