
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.17,
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

