<div align="center">
  <h1>Haskell Four-Bar Linkage Simulator</h1>
  <p>
    A browser-backed desktop-style GUI application written in <strong>Haskell</strong> with
    <strong>Threepenny-GUI</strong> for visualizing, classifying, and animating the planar
    four-bar linkage mechanism used in mechanism design and mechanical engineering courses.
  </p>
</div>

<hr />

<h2>Project Overview</h2>

<p>
This version replaces the previous <code>Gloss</code> GUI with a <strong>Threepenny-GUI + HTML/CSS/SVG</strong>
interface. The pure Haskell mechanism solver remains in <code>src/FourBar.hs</code>, while
<code>app/Main.hs</code> now builds a responsive browser-rendered GUI. The application runs a local GUI
server and displays the interface in a web browser at <code>http://127.0.0.1:8023</code>.
</p>

<p>
Reference model: <a href="https://dynref.engr.illinois.edu/aml.html">University of Illinois Dynamics Reference — Four-Bar Linkages</a>.
</p>

<h3>Main GUI Features</h3>

<ul>
  <li><strong>Threepenny GUI:</strong> uses the browser as the display layer while the application logic stays in Haskell.</li>
  <li><strong>Local font support:</strong> loads <code>resources/fonts/Inter-Regular.ttf</code> through CSS <code>@font-face</code>.</li>
  <li><strong>Responsive 16:9 layout:</strong> the full app is drawn inside a proportional 16:9 shell.</li>
  <li><strong>Minimum width:</strong> the app shell uses a <code>650px</code> minimum width and shows a warning below that size.</li>
  <li><strong>Left pane:</strong> occupies 20% of the application width and contains four horizontal sliders.</li>
  <li><strong>Link length sliders:</strong> tune <code>g</code>, <code>a</code>, <code>b</code>, and <code>f</code> from <code>5 cm</code> to <code>40 cm</code>.</li>
  <li><strong>SVG visualization:</strong> the four-bar mechanism is redrawn as scalable browser SVG.</li>
  <li><strong>Animation:</strong> a Play/Pause button starts and stops input-link motion.</li>
  <li><strong>Angle display:</strong> live input angle <code>α</code> and output angle <code>β</code>.</li>
  <li><strong>Mechanism classification:</strong> Grashof/non-Grashof, valid/invalid assembly, and crank/rocker state.</li>
  <li><strong>Keyboard controls:</strong> <code>Space</code> toggles Play/Pause, <code>F</code> flips the assembly branch, and <code>R</code> resets the mechanism.</li>
</ul>

<hr />

<h2>Mechanism Design Theory</h2>

<h3>Planar Mechanisms and Mobility</h3>

<p>
A planar mechanism is a system of rigid bodies connected by joints so that the bodies move in a plane. For a planar linkage
with <code>n</code> links, <code>j1</code> lower pairs such as pin or slider joints, and <code>j2</code> higher pairs, the Kutzbach-Grübler mobility
equation is commonly written as:
</p>

<p>
$$
M = 3(n - 1) - 2j_1 - j_2.
$$
</p>

<p>
For a four-bar linkage, there are four links and four pin joints:
</p>

<p>
$$
M = 3(4 - 1) - 2(4) = 9 - 8 = 1.
$$
</p>

<p>
Therefore, an ideal planar four-bar linkage has exactly <strong>one degree of freedom</strong>. Once the input angle <code>α</code> is chosen,
the other moving link positions are determined by the loop-closure constraints, except for the assembly branch.
</p>

<h2>Four-Bar Linkage Model</h2>

<table>
  <thead>
    <tr>
      <th>Symbol</th>
      <th>Name</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>g</code></td><td>Ground link</td><td>Fixed distance between pivots <code>A</code> and <code>B</code>.</td></tr>
    <tr><td><code>a</code></td><td>Input link</td><td>Driven link from <code>A</code> to moving pivot <code>C</code>; its angle is <code>α</code>.</td></tr>
    <tr><td><code>b</code></td><td>Output link</td><td>Link from fixed pivot <code>B</code> to moving pivot <code>D</code>; its angle is <code>β</code>.</td></tr>
    <tr><td><code>f</code></td><td>Floating link / coupler</td><td>Connects moving pivots <code>C</code> and <code>D</code>.</td></tr>
  </tbody>
</table>

<p>
The fixed pivots are placed at:
</p>

<p>
$$
A = (0,0), \qquad B = (g,0).
$$
</p>

<p>
The input point <code>C</code> is determined by:
</p>

<p>
$$
C = (a\cos\alpha,\; a\sin\alpha).
$$
</p>

<p>
The output point <code>D</code> must satisfy:
</p>

<p>
$$
\|D - C\| = f, \qquad \|D - B\| = b.
$$
</p>

<p>
The simulator solves this by circle intersection. A real assembly exists for the current input angle when:
</p>

<p>
$$
|f - b| \le d \le f + b,
$$
</p>

<p>
where <code>d = ||B - C||</code>. The two possible circle intersections correspond to the two assembly branches; pressing
<code>F</code> flips between them.
</p>

<hr />

<h2>Grashof and Validity Indices</h2>

<p>
Let the four link lengths be sorted as:
</p>

<p>
$$
s \le p \le q \le l,
$$
</p>

<p>
where <code>s</code> is the shortest link and <code>l</code> is the longest link.
</p>

<h3>Grashof Index</h3>

<p>
$$
G = s + l - p - q.
$$
</p>

<ul>
  <li><code>G &lt; 0</code>: Grashof mechanism.</li>
  <li><code>G = 0</code>: change-point mechanism.</li>
  <li><code>G &gt; 0</code>: non-Grashof mechanism.</li>
</ul>

<h3>Validity Index</h3>

<p>
$$
V = l - s - p - q.
$$
</p>

<p>
A physically assemblable four-bar must satisfy <code>V &lt;= 0</code>. If <code>V &gt; 0</code>, the longest link is longer than the sum of
the other three links, so the mechanism cannot close.
</p>

<hr />

<h2>Full Linkage Model State Classification</h2>

<p>
The simulator computes:
</p>

<p>
$$
T_1 = g + f - b - a, \qquad
T_2 = b + g - f - a, \qquad
T_3 = f + b - g - a.
$$
</p>

<p>
The signs of <code>T1</code>, <code>T2</code>, and <code>T3</code> determine whether the input and output are cranks, rockers,
<code>0-rockers</code>, or <code>π-rockers</code>. The GUI displays both the detailed state and the collapsed basic state:
</p>

<ul>
  <li><code>crank - crank</code></li>
  <li><code>crank - rocker</code></li>
  <li><code>rocker - rocker</code></li>
  <li><code>rocker - crank</code></li>
</ul>

<hr />

<h2>Repository Structure</h2>

<pre><code>fourbar-linkage-threepenny/
├── app/
│   └── Main.hs
├── src/
│   └── FourBar.hs
├── resources/
│   └── fonts/
│       └── Inter-Regular.ttf
├── fourbar-linkage-threepenny.cabal
├── README.md
├── LICENSE
└── .gitignore
</code></pre>

<h3><code>src/FourBar.hs</code></h3>

<p>
This module contains the pure mechanism mathematics and classification logic. It is intentionally separated from the GUI so
that future versions can reuse the solver in tests, command-line tools, notebooks, or web backends.
</p>

<ul>
  <li><code>Linkage</code>: stores <code>g</code>, <code>a</code>, <code>b</code>, and <code>f</code>.</li>
  <li><code>Pose</code>: stores the coordinates of pivots <code>A</code>, <code>B</code>, <code>C</code>, and <code>D</code>, plus <code>α</code> and <code>β</code>.</li>
  <li><code>excesses</code>: computes <code>T1</code>, <code>T2</code>, and <code>T3</code>.</li>
  <li><code>grashofIndex</code>: computes <code>G = s + l - p - q</code>.</li>
  <li><code>validityIndex</code>: computes <code>V = l - s - p - q</code>.</li>
  <li><code>classifyMotion</code>: returns detailed labels such as <code>crank</code>, <code>rocker</code>, <code>0-rocker</code>, and <code>π-rocker</code>.</li>
  <li><code>solvePose</code>: solves the four-bar geometry using circle intersections.</li>
  <li><code>nearestValidAlpha</code>: finds a nearby valid angle after parameter changes.</li>
</ul>

<h3><code>app/Main.hs</code></h3>

<p>
This module now contains the Threepenny GUI and event loop. It builds DOM controls for the sliders and buttons, renders the
mechanism as responsive SVG, loads the local Inter font through CSS, and updates the application state from Haskell.
</p>

<ul>
  <li><code>setup</code>: builds the page, sliders, readouts, buttons, and SVG container.</li>
  <li><code>renderWorld</code>: synchronizes the browser GUI with the Haskell <code>World</code> state.</li>
  <li><code>mechanismSvg</code>: generates the current linkage drawing as SVG.</li>
  <li><code>animationLoop</code>: advances the mechanism while Play is active.</li>
  <li><code>updateSliderValue</code>: applies slider changes to the pure linkage model.</li>
</ul>

<hr />

<h2>How to Install Haskell and Run the App</h2>

<p>
The recommended installation route is <strong>GHCup</strong>, which installs <code>ghc</code>, <code>cabal</code>, and optional development tools.
</p>

<p>
Official Haskell download page: <a href="https://www.haskell.org/downloads/">https://www.haskell.org/downloads/</a><br />
Official GHCup installation page: <a href="https://www.haskell.org/ghcup/install/">https://www.haskell.org/ghcup/install/</a>
</p>

<h3>Windows</h3>

<pre><code>Set-ExecutionPolicy Bypass -Scope Process -Force;[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; try { &amp; ([ScriptBlock]::Create((Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing))) -Interactive -DisableCurl } catch { Write-Error $_ }
</code></pre>

<p>After installation, close and reopen PowerShell, then verify:</p>

<pre><code>ghc --version
cabal --version</code></pre>

<p>Run the simulator:</p>

<pre><code>git clone https://github.com/mohammadijoo/Four-Bar-Mechanism-Haskell.git
cd Four-Bar-Mechanism-Haskell
cabal update
cabal run fourbar-linkage-threepenny</code></pre>

<p>
Then open <code>http://127.0.0.1:8023</code> if the browser does not open automatically.
</p>

<h3>macOS / Linux</h3>

<pre><code>curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
</code></pre>

<p>Restart the terminal, then verify:</p>

<pre><code>ghc --version
cabal --version</code></pre>

<p>Run the simulator:</p>

<pre><code>git clone https://github.com/mohammadijoo/Four-Bar-Mechanism-Haskell.git
cd Four-Bar-Mechanism-Haskell
cabal update
cabal run fourbar-linkage-threepenny</code></pre>

<hr />

<h2>Controls</h2>

<table>
  <thead>
    <tr><th>Control</th><th>Action</th></tr>
  </thead>
  <tbody>
    <tr><td>Drag <code>g</code> slider</td><td>Change ground link length.</td></tr>
    <tr><td>Drag <code>a</code> slider</td><td>Change input link length.</td></tr>
    <tr><td>Drag <code>b</code> slider</td><td>Change output link length.</td></tr>
    <tr><td>Drag <code>f</code> slider</td><td>Change floating/coupler link length.</td></tr>
    <tr><td>Click <code>Play</code> / <code>Pause</code></td><td>Start or stop the animation.</td></tr>
    <tr><td>Click <code>Flip branch</code></td><td>Switch between the two possible assembly branches.</td></tr>
    <tr><td>Click <code>Reset</code></td><td>Restore the default linkage.</td></tr>
    <tr><td><code>Space</code></td><td>Toggle Play/Pause.</td></tr>
    <tr><td><code>F</code></td><td>Flip between assembly branches.</td></tr>
    <tr><td><code>R</code></td><td>Reset the mechanism.</td></tr>
  </tbody>
</table>

<hr />

<h2>Troubleshooting</h2>

<h3>Browser does not open automatically</h3>

<p>
Threepenny starts a local GUI server. If the browser is not launched automatically, open:
</p>

<pre><code>http://127.0.0.1:8023</code></pre>

<h3>Port 8023 is already in use</h3>

<p>
Close the older running instance, or change <code>jsPort = Just 8023</code> in <code>app/Main.hs</code> to another port such as
<code>8024</code>.
</p>

<h3>Local Inter font is not visible</h3>

<p>
Make sure the file exists exactly here:
</p>

<pre><code>resources/fonts/Inter-Regular.ttf</code></pre>

<p>
Also make sure you run <code>cabal run</code> from the project root, because the static file server is configured with
<code>jsStatic = Just "."</code>.
</p>

<h3>Gloss / GLUT errors are gone</h3>

<p>
This project no longer depends on <code>gloss</code>, OpenGL, or GLUT. The old <code>unknown GLUT entry glutInit</code> Windows problem does
not apply to this Threepenny version.
</p>

<h3>Responsive window behavior</h3>

<p>
The application shell uses CSS <code>aspect-ratio: 16 / 9</code>. The shell grows to the largest 16:9 rectangle that fits inside the
browser viewport. It uses a <code>650px</code> minimum width. On a viewport narrower than that, the app may horizontally clip and a
warning is displayed.
</p>

<hr />

<h2>Suggested Future Improvements</h2>

<ul>
  <li>Add a coupler point <code>P</code> and trace its curve.</li>
  <li>Add export of linkage motion data as CSV.</li>
  <li>Add velocity and acceleration analysis using differentiated loop-closure equations.</li>
  <li>Add force transmission angle and mechanical advantage plots.</li>
  <li>Add automated tests for the classification table.</li>
  <li>Add an Electron wrapper for a packaged desktop executable.</li>
</ul>

<hr />

<a id="simulation-video"></a>

## Simulation video

Below is a link to the simulation video on YouTube.

<a href="#" target="_blank">
  <img
    src="https://i.ytimg.com/vi/some_ID/maxresdefault.jpg"
    alt="Four Bar Linkage Mechanism in Haskell"
    style="max-width: 100%; border-radius: 10px; box-shadow: 0 6px 18px rgba(0,0,0,0.18); margin-top: 0.5rem;"
  />
</a>

---

<h2>License</h2>

<p>
This project is released under the MIT License. See <code>LICENSE</code> for details.
</p>
