package XML::Xerces::BagOfTricks;

our $VERSION = '0.01';

=head1 NAME

XML::Xerces::BagOfTricks - Perl library holding handy stuff for XML:Xerces

=head1 SYNOPSIS

  use XML::Xerces::BagOfTricks;

  # get a nice DOM Document
  my $DOMDocument = getDocument($namespace,$root_tag);

  # get a nice Element containing a text node (i.e. <foo>bar</foo>)
  my $foo_elem = getTextElement($DOMDocument,'Foo','Bar');

  # if node is not of type Element then append its data to $contents
  if ( $NodeType[$node->getNodeType()] ne 'Element' ) {
	    $contents .= $node->getData();
  }

  # or the easier..
  my $content = getTextContents($node);

  # get the nice DOM Document as XML
  my $xml = getXML($DOMDocument);

=head1 DESCRIPTION

This module is designed to provide a bag of tricks for users of
XML::Xerces DOM API. It provides some useful variables for
looking up xerces-c enum values. There should also be some useful
functions.

getTextContents() from 'Effective XML processing with DOM and XPath in Perl' 
by Parand Tony Darugar (tdarugar@velocigen.com) IBM Developerworks Oct 1st 2001

=head2 EXPORT

all - %NodeType @NodeType &getTextContents &getDocument &getXML &getTextElement

=head1 FUNCTIONS

=cut

use strict;

use XML::Xerces;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	%NodeType @NodeType &getTextContents &getDocument &getXML &getTextElement
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
#
#);

my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
my $writer = $impl->createDOMWriter();
if ($writer->canSetFeature('format-pretty-print',1)) {
    $writer->setFeature('format-pretty-print',1);
}

our %NodeType;
our @NodeType = qw(ERROR ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE );
@NodeType{@NodeType} = ( 0 .. 13 );

# Preloaded methods go here.

# blatently nicked from 'Effective XML processing with DOM and XPath in Perl'
# by Parand Tony Darugar (tdarugar@velocigen.com) IBM Developerworks Oct 1st 2001

=head2 getTextContents($node)

returns the text content of a node (and its subnodes)

my $content = getTextContents($node);

Function by P T Darugar, published in IBM Developerworks Oct 1st 2001

=cut
sub getTextContents {
    my ($node, $strip)= @_;
    my $contents;

    if (! $node ) {
	return;
    }
    for my $child ($node->getChildNodes()) {
	warn "node type : ", $NodeType[$child->getNodeType()];
	if ( $NodeType[$child->getNodeType()] =~ /(?:TEXT|CDATA_SECTION)_NODE/ ) {
	    $contents .= $child->getData();
	}
    }

    if ($strip) {
	$contents =~ s/^\s+//;
	$contents =~ s/\s+$//;
    }

    return $contents;
}

=head2 getTextElement($doc,$name,$value)

    This function returns a nice XML::Xerces::DOMNode representing an element
    with an appended Text subnode, based on the arguments provided.

    In the example below $node would represent '<Foo>Bar</Foo>'

    my $node = getTextElement($doc,'Foo','Bar');

    More useful than a pocketful of bent drawing pins! If only the Chilli Peppers
    made music like they used to 'Zephyr' is no equal of 'Fight Like A Brave' or
    'Give it away'

=cut

sub getTextElement {
    my ($doc, $name, $value) = @_;
    warn caller() unless $value;
    my $field = $doc->createElement($name);
    my $fieldvalue = $doc->createTextNode($value);
    $field->appendChild($fieldvalue);
    return $field;
}

=head2 getDocument($namespace,$root_tag)

This function will return a nice XML:Xerces::DOMDocument object.

It requires a namespace, a root tag, and a list of tags to be added to the document

the tags can be scalars :

my $doc = getDocument('http://www.some.org/schema/year foo.xsd', 'Foo', 'Bar', 'Baz');

or a hashref of attributes, and the tags name :

my $doc = getDocument($ns,{name=>'Foo', xmlns=>'http://www.other.org/namespace', version=>1.3}, 'Bar', 'Baz');

=cut

# maybe we should memoize this later

sub getDocument {
    my ($ns,$root_tag,@tags) = @_;
    my $docroot = (ref $root_tag) ? $root_tag->{name} : $root_tag;
    my $doc = eval{$impl->createDocument($ns, $docroot, undef)};
    XML::Xerces::error($@) if $@;
    my $root = $doc->getDocumentElement();
    if (ref $root_tag) {
	foreach (keys %$root_tag) {
	    next if /name/;
	    $root->setAttribute($_,$root_tag->{$_});
	}
    }
    foreach my $tag ( @tags ) {
	my $element_tag = (ref $tag) ? $tag->{name} : $tag;
	my $element = $doc->createElement ($element_tag);
	if (ref $tag) {
	    foreach (keys %$tag) {
		next if /name/;
		$element->setAttribute($_,$tag->{$_});
	    }
	}
	$root->appendChild($element);
    }
    return $doc;

}

=head2 getXML($DOMDocument)

getXML is exported in the ':all' tag and will return XML in a string
generated from the DOM Document passed to it

my $xml = getXML($doc);

=cut

sub getXML {
    my $doc = shift;
    my $target = XML::Xerces::MemBufFormatTarget->new();
    $writer->writeNode($target,$doc);
    my $xml = $target->getRawBuffer;
    return $xml;
}


################################################################

1;

__END__

=head1 SEE ALSO

XML::Xerces

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Aaron Trevena, Surrey Technologies, Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
