use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'PHP::DateTime',
	'VERSION_FROM' => 'DateTime.pm',
	'PREREQ_PM' => {},
	($] >= 5.005 ? (
		ABSTRACT_FROM => 'DateTime.pm',
		AUTHOR => 'Aran Clary Deltac <aran@bluefeet.net>'
	) : ()),
);
