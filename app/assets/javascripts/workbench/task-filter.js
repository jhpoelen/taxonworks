var carrouselTask = function (sec, rows, columns) {
  // sec = Name of data section, this is for identify div.
  // rows = This is for the number of rows that will be displayed, if this number is less than the number of items, it will activate the navigation controls
  
    this.childs = [],
    this.start = 1,
    this.middleBoxSize = 650,
    this.boxSize = 500,
    this.active = [];
    this.arrayPos = 1;
    this.maxRow = 3,
    this.childsCount = 0,
    this.sectionTag = "",
    this.filters = {},
    this.maxRow = rows,
    this.sectionTag = sec;
    this.resetChildsCount();
    this.makeInjection();
  }

  carrouselTask.prototype.makeInjection = function () {
    $('div.source').replaceWith('<img class="categories source" src="/assets/icons/book.svg" width="15"/>');
    $('div.collecting_event').replaceWith('<img class="categories collecting_event" src="/assets/icons/geo_location.svg" alt="Collection object" width="15"/>');
    $('div.collection_object').replaceWith('<img class="categories collection_object" src="/assets/icons/picking.svg" width="15"/>');
  } 

  carrouselTask.prototype.addFilter = function (nameFilter) {
    this.filters[nameFilter] = false;
  } 
  carrouselTask.prototype.checkChildFilter = function(childTag) {
    var find = 0;
    var isTrue = 0;
    for (var key in this.filters) {
      if(this.filters[key] == true) {
        find++;      
        if (childTag.find('.'+ key).hasClass(key)) {
          isTrue++;
        } 
      }
    }
    if(isTrue == find) {
      return true;
    }
    else {
      return false;
    }
  }
  carrouselTask.prototype.resetChildsCount = function() {
      this.childsCount = $(this.sectionTag + ' > .task_card').length;
  }
  carrouselTask.prototype.setFilterStatus = function(filterTag, value)  {
    this.filters[filterTag] = value;
    this.filterChilds();
  } 
  carrouselTask.prototype.changeFilter = function(filterTag)  {
    this.filters[filterTag] = !this.filters[filterTag];
    this.filterChilds();
  } 
  carrouselTask.prototype.showChilds = function() {
    var 
      count = 1;
    
    for (i = 1; i <= this.childs.length; i++) {
      child = $(this.sectionTag + ' > .task_card:nth-child('+ (i) +')');
      if(this.childs[i]) {
        if(count <= this.maxRow) {
          if(count == Math.round(this.maxRow/2)) {
            $(this.sectionTag + " > .task_card:nth-child("+ i +")" ).children(".task_card").css("width",this.middleBoxSize);
          }
          else {
            $(this.sectionTag + " > .task_card:nth-child("+ i +")" ).children(".task_card").css("width",this.boxSize);
          }
          count++;
          child.show(250);
        }
      }
      else {
        child.hide(250);
      }
    }
  }
  carrouselTask.prototype.filterChilds = function() {
    var 
      find = 0,
      activeCount = 0;
      this.arrayPos = 0;
      this.active = [];
      this.childs = [];
    for (i = 1; i <= this.childsCount; i++) {
      child = $(this.sectionTag + ' > .task_card:nth-child('+ (i) +')');
      if(this.checkChildFilter(child)) {
        this.active[activeCount] = i;
        activeCount++;
        this.childs[i] = true;
        find++;
      }
    }
    this.navigation((find > this.maxRow));
  } 
  carrouselTask.prototype.resetView = function() {
    $(this.sectionTag + ' .task_card').css("display","none");
  }
  carrouselTask.prototype.navigation = function(value) {
    if(value) {
      $(this.sectionTag + " > .navigation a").show(250);
    }
    else {
      $(this.sectionTag + " > .navigation a").hide(250);
    }
  }
  carrouselTask.prototype.loadingDown = function() {
    var 
      boxSize = this.boxSize,
      middleBoxSize = this.middleBoxSize,
      sectionTag = this.sectionTag,
      arrayPos = this.arrayPos,
      active = this.active;
      maxRow = this.maxRow;
      if(this.active.length > (this.arrayPos + maxRow)) {
        if((arrayPos+maxRow) <= this.childsCount) {
          $(sectionTag + " > .task_card:nth-child("+ active[arrayPos] +")" ).hide(100, function() {
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos+2] +")" ).children(".task_card").animate({
              width: middleBoxSize
            }, 50);
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos+1] +")" ).children(".task_card").animate({
              width: boxSize
            }, 50); 
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos] +")" ).children(".task_card").animate({
              width: boxSize
            }, 50);       
            $(sectionTag + " > .task_card:nth-child("+ active[arrayPos+3] +")" ).show(150)
          });   
          if(this.arrayPos <= this.active.length) {
            this.arrayPos++;
          }      
        }      
      } 
  }
  carrouselTask.prototype.loadingUp = function() {
    var 
      boxSize = this.boxSize,
      middleBoxSize = this.middleBoxSize,
      sectionTag = this.sectionTag,
      arrayPos = this.arrayPos,
      active = this.active;
      maxRow = this.maxRow;
      if(0 < (this.arrayPos + maxRow)) {
        if((arrayPos) > 0) {
          $(sectionTag + " > .task_card:nth-child("+ active[arrayPos+maxRow-1] +")" ).hide(100, function() {
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos] +")" ).children(".task_card").animate({
              width: middleBoxSize
            }, 50);
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos+maxRow-1] +")" ).children(".task_card").animate({
              width: boxSize
            }, 50); 
            $(sectionTag + " .task_card:nth-child("+ active[arrayPos+1] +")" ).children(".task_card").animate({
              width: boxSize
            }, 50);       
            $(sectionTag + " > .task_card:nth-child("+ active[arrayPos-1] +")" ).show(150)
          });   
          if(this.arrayPos > 0) {
            this.arrayPos--;
          }      
        }      
      } 
  }