
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.15,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

