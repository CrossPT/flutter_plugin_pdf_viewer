class PDFViewerTooltip {
  final String first;
  final String previous;
  final String next;
  final String last;
  final String pick;
  final String jump;

  const PDFViewerTooltip(
      {this.first = "First",
      this.previous = "Previous",
      this.next = "Next",
      this.last = "Last",
      this.pick = "Pick a page",
      this.jump = "Jump"});
}
