import './monaco'
import { @watch } from '../decorators'
import {ls, File, Folder} from '../store'
import * as sw from '../sw/controller'

import './console'

const editorOptions = {
	scrollBeyondLastLine: false
	readOnly: false
	theme: 'scrimba-dark'
	wordWrapColumn: 100
	wordWrap: 'wordWrapColumn'
	wrappingIndent: "same"
	fontIsMonospace: true
	hideCursorInOverviewRuler: true,
	lineNumbersMinChars: 5,
	lineNumbers: true
	fontSize: 13
	minimap: {enabled: false}
	renderLineHighlight: 'none'
	renderIndentGuides: false
	cursorBlinking: 'smooth'
	matchBrackets: 'never'
	codeLens: false
	detectIndentation: true,
	selectionHighlight: false,
	occurrencesHighlight: false,
	links: false,
	scrollbar: {
		useShadows: false
		verticalScrollbarSize: 8
		horizontalScrollbarSize: 8
	}
}

tag app-repl
	prop fs
	@watch prop project
	@watch prop currentFile
	@watch prop url

	get monaco
		return $monaco if !global.monaco or $monaco or !$editor
		$monaco = global.monaco.editor.create($editor,editorOptions)
		$monaco.updateOptions(editorOptions)
		$monaco.setModel(currentFile.model) if currentFile
		$monaco
	
	def build
		examples = ls('/examples')
		$placeholder = self # for the router
	
		$iframe = <iframe.inset-0.absolute .(position:absolute width:100% height:100%)>
		$iframe.replify = do(win)
			$win = win # $iframe.contentWindow
			$doc = $win.document

			let {log,info} = win.console.log
			if $console
				$console.context = win
				$console.native = win.console
				win.console.log = $console.log.bind($console)
				win.console.info = $console.info.bind($console)

		$iframe.onload = do
			try
				let element = $doc.querySelector('body :not(script)')
				flags.toggle('empty-preview',!element)

		sw.on 'reload' do reload!
		self

	def reload
		$console.clear! if $console
		try $iframe.contentWindow.location.reload!

	def run
		let index = project.childByName('index.html')
		let app = project.childByName('app.imba') or currentFile
		$console.clear! if $console
		url = `{project.path}/{index ? index.name : app.basename + '.html'}`
		self

	def project-did-set project
		if project
			if (!currentFile or currentFile.parent != project)
				currentFile = project.files[0]
			run!

	def currentFile-did-set file
		if monaco and file
			monaco.setModel(file.model)

		project = file.parent
		if !project.childByName('index.html') and !project.childByName('app.imba')
			run!

	def url-did-set url
		try
			$iframe.contentWindow.location.replace(`/repl{url}`)
		catch e
			$iframe.src = `/repl{url}`

	def relayout
		if $monaco
			$monaco.layout(height: $editor.offsetHeight, width: $editor.offsetWidth)

	def leave
		router.go($parent.guide.path)

	def routeDidResolve match, prev,last
		let item = ls(match.url)
		if item isa File
			currentFile = item
		elif item isa Folder
			if item.files[0]
				router.go(item.files[0].path)
				render!

	def show
		router.go(currentFile ? currentFile.path : '/examples/essentials/playground/app.imba')

	css & = overscroll-behavior: contain
	css header = p:2 3 d:flex ai:center t:sm 500 gray600
	css .tab = radius:2 py:1 px:2 t.hover:gray500 t.is-active:blue400
	css .dark .tab = bg.is-active:gray800 shadow.is-active:sm
	css .light .tab = t.hover:gray600 t.is-active:gray600 undecorated
	css .underlay = l:fixed inset:0 z-index:-1 bg:hsla(214,35%,83%,0.6) d.in-hidden:none

	css &.empty-preview
		& $console = flex-grow:1
		& $preview = display:none

	css $sidebar
		bg:gray800 w:240px cursor:default l:rel block t:gray500

		&:after
			content: ' '
			bg: linear-gradient(gray800-0,gray800-100)
			l: block abs width: 90% height: 80px bottom: 0

		& .scroller
			-webkit-overflow-scrolling: touch
			l: abs scroll-y inset:0 pb:5

		& .item
			t:sm/1.3 gray600-70 500 capitalize t.hover:gray500
			p:1 7 l:block bg.hover:gray900-10
			&.active = bg:gray900-20 t:white bold

	def save
		currentFile.save!
		self

	def render
		<self>
			<div.underlay @click=leave @wheel.stop.prevent>
			<div$sidebar>
				<.scroller>
					<div$back.(l:block p:3 5 t:sm 500 blue400 t.hover:underline) @click=leave> "⇦ back to site"
					<div.items> for child in examples.children
						<h5.(p:1 7 t:xs gray600 bold)> child.title.toUpperCase!
						<div.(pb:5)> for item in child.children
							<a.item route-to.sticky=item.path> item.title

			<div.dark.(l:vflex rel flex:70% bg:#29313f) @resize=relayout>
				<header.(color:gray600)>
					<div.(d:contents cursor:default)> for file in project..children
						<a.tab route-to.replace=file.path data-route=file.path>
							<span.name> file.basename
							<span.ext.{file.ext}.(d.is-imba:none)> "." + file.ext

					<div.(flex:1)>
					<button @click=save> "save"

				<div$editor.(l:abs inset:12 0 0)>

			<div.light.(l:vflex flex:1 1 30% bg:white)>
				<div$preview.(l:vflex flex:1)>
					<header.(bg:gray200)> <.tab.active> "Preview"
					<div.(l:rel flex:1)> <div$browserframe.(l:abs inset:0)> $iframe
				<div.divider>
				<repl-console$console.(flex-basis:40% l:vflex)>

	def rendered
		monaco